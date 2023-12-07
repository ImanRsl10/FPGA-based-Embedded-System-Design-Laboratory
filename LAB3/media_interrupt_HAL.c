#include "globals.h"
#include "sys/alt_timestamp.h"
#include "system.h"
/* these globals are written by interrupt service routines; we have to declare 
 * these as volatile to avoid the compiler caching their values in registers */

extern volatile unsigned char byte1, byte2, byte3;		/* modified by PS/2 interrupt service routine */
extern volatile int timeout;							// used to synchronize with the timer
extern struct alt_up_dev up_dev;						/* pointer to struct that holds pointers toopen devices */

volatile int buf_index_record;
volatile int buf_index_play;
volatile int packet_ready;
volatile int KEY_value;

volatile unsigned char mouse_packet[3];
volatile unsigned int l_buf[BUF_SIZE], r_buf[BUF_SIZE], el_buf[BUF_SIZE], er_buf[BUF_SIZE];

volatile int mouse_icon[16][8] = {
								  {0,-1,-1,-1,-1,-1,-1,-1},
								  {0,0,-1,-1,-1,-1,-1,-1},
								  {0,1,0,-1,-1,-1,-1,-1},
								  {0,1,1,0,-1,-1,-1,-1},
								  {0,1,1,1,0,-1,-1,-1},
								  {0,1,1,1,1,0,-1,-1},
								  {0,1,1,1,1,1,0,-1},
								  {0,1,1,1,1,0,0,0},
								  {0,1,1,1,0,-1,-1,-1},
								  {0,0,0,1,0,-1,-1,-1},
								  {0,-1,0,1,0,-1,-1,-1},
								  {-1,-1,-1,0,1,0,-1,-1},
								  {-1,-1,-1,0,1,0,-1,-1},
								  {-1,-1,-1,-1,0,1,0,-1},
								  {-1,-1,-1,-1,0,1,0,-1},
								  {-1,-1,-1,-1,-1,0,-1,-1}
								 };;

/* function prototypes */
void HEX_PS2(unsigned char, unsigned char, unsigned char, unsigned char);
void interval_timer_ISR(void *, unsigned int);
void pushbutton_ISR(void *, unsigned int);
void audio_ISR(void *, unsigned int);
void PS2_ISR(void *, unsigned int);
int Erase_mouse(alt_up_pixel_buffer_dma_dev *, int, int, int , int, int , int , short, short);
void draw_mouse(alt_up_pixel_buffer_dma_dev *, int, int);
int erase_mouse(alt_up_pixel_buffer_dma_dev *, int, int, int, int, int, int, short, short);
void filter_noise_sw();

/********************************************************************************
 * This program demonstrates use of the media ports in the DE2 Media Computer
 *
 * It performs the following: 
 *  	1. records audio for about 10 seconds when an interrupt is generated by
 *  	   pressing KEY[1]. LEDG[0] is lit while recording. Audio recording is 
 *  	   controlled by using interrupts
 * 	2. plays the recorded audio when an interrupt is generated by pressing
 * 	   KEY[2]. LEDG[1] is lit while playing. Audio playback is controlled by 
 * 	   using interrupts
 * 	3. Draws a blue box on the VGA display, and places a text string inside
 * 	   the box. Also, moves the word ALTERA around the display, "bouncing" off
 * 	   the blue box and screen edges
 * 	4. Shows a text message on the LCD display, and scrolls the message
 * 	5. Displays the last three bytes of data received from the PS/2 port 
 * 	   on the HEX displays on the DE2 board. The PS/2 port is handled using 
 * 	   interrupts
 * 	6. The speed of scrolling the LCD display and of refreshing the VGA screen
 * 	   are controlled by interrupts from the interval timer
********************************************************************************/
int main(void)
{
	/* declare device driver pointers for devices */
	alt_up_parallel_port_dev *KEY_dev;
	alt_up_parallel_port_dev *green_LEDs_dev;
	alt_up_ps2_dev *PS2_dev;
	alt_up_character_lcd_dev *lcd_dev;
	alt_up_audio_dev *audio_dev;
	alt_up_char_buffer_dev *char_buffer_dev;
	alt_up_pixel_buffer_dma_dev *pixel_buffer_dev;
	/* declare volatile pointer for interval timer, which does not have HAL functions */
	volatile int * interval_timer_ptr = (int *) 0x10002000;	// interal timer base address

	// /* initialize some variables */
	// byte1 = 0; byte2 = 0; byte3 = 0; 			// used to hold PS/2 data
	// timeout = 0;										// synchronize with the timer

	/* these variables are used for a blue box and a "bouncing" ALTERA on the VGA screen */
	int blue1_x1; int blue1_y1; int blue1_x2; int blue1_y2;
	int blue2_x1; int blue2_y1; int blue2_x2; int blue2_y2;
	int blue3_x1; int blue3_y1; int blue3_x2; int blue3_y2;
	int screen_x; int screen_y; int char_buffer_x; int char_buffer_y;
	short background_color, mouse_color, color;
	int center_x = 5, center_y = 5;

	/* set the interval timer period for scrolling the HEX displays */
	int counter = 0x960000;				// 1/(50 MHz) x (0x960000) ~= 200 msec
	*(interval_timer_ptr + 0x2) = (counter & 0xFFFF);
	*(interval_timer_ptr + 0x3) = (counter >> 16) & 0xFFFF;

	/* start interval timer, enable its interrupts */
	*(interval_timer_ptr + 1) = 0x7;	// STOP = 0, START = 1, CONT = 1, ITO = 1 
	
	// open the pushbuttom KEY parallel port
	KEY_dev = alt_up_parallel_port_open_dev ("/dev/Pushbuttons");
	if ( KEY_dev == NULL)
	{
		alt_printf ("Error: could not open pushbutton KEY device\n");
		return -1;
	}
	else
	{
		alt_printf ("Opened pushbutton KEY device\n");
		up_dev.KEY_dev = KEY_dev;	// store for use by ISRs
	}
	/* write to the pushbutton interrupt mask register, and set 3 mask bits to 1 
	 * (bit 0 is Nios II reset) */
	alt_up_parallel_port_set_interrupt_mask (KEY_dev, 0xE);

	// open the green LEDs parallel port
	green_LEDs_dev = alt_up_parallel_port_open_dev ("/dev/Green_LEDs");
	if ( green_LEDs_dev == NULL)
	{
		alt_printf ("Error: could not open green LEDs device\n");
		return -1;
	}
	else
	{
		alt_printf ("Opened green LEDs device\n");
		up_dev.green_LEDs_dev = green_LEDs_dev;	// store for use by ISRs
	}

	// open the PS2 port
	PS2_dev = alt_up_ps2_open_dev ("/dev/PS2_Port");
	if ( PS2_dev == NULL)
	{
		alt_printf ("Error: could not open PS2 device\n");
		return -1;
	}
	else
	{
		alt_printf ("Opened PS2 device\n");
		up_dev.PS2_dev = PS2_dev;	// store for use by ISRs
	}
	(void) alt_up_ps2_write_data_byte (PS2_dev, 0xFF);		// reset
	alt_up_ps2_enable_read_interrupt (PS2_dev); // enable interrupts from PS/2 port

	// open the audio port
	audio_dev = alt_up_audio_open_dev ("/dev/Audio");
	if ( audio_dev == NULL)
	{
		alt_printf ("Error: could not open audio device\n");
		return -1;
	}
	else
	{
		alt_printf ("Opened audio device\n");
		up_dev.audio_dev = audio_dev;	// store for use by ISRs
	}

	// open the 16x2 character display port
	lcd_dev = alt_up_character_lcd_open_dev ("/dev/Char_LCD_16x2");
	if ( lcd_dev == NULL)
	{
		alt_printf ("Error: could not open character LCD device\n");
		return -1;
	}
	else
	{
		alt_printf ("Opened character LCD device\n");
		up_dev.lcd_dev = lcd_dev;	// store for use by ISRs
	}

	/* use the HAL facility for registering interrupt service routines. */
	/* Note: we are passsing a pointer to up_dev to each ISR (using the context argument) as 
	 * a way of giving the ISR a pointer to every open device. This is useful because some of the
	 * ISRs need to access more than just one device (e.g. the pushbutton ISR accesses both
	 * the pushbutton device and the audio device) */
	alt_irq_register (0, (void *) &up_dev, (void *) interval_timer_ISR);
	alt_irq_register (1, (void *) &up_dev, (void *) pushbutton_ISR);
	alt_irq_register (6, (void *) &up_dev, (void *) audio_ISR);
	alt_irq_register (7, (void *) &up_dev, (void *) PS2_ISR);

	/* create a messages to be displayed on the VGA and LCD displays */
	char text_top_LCD[80] = "Welcome to the DE2 Media Computer...\0";
	char text_RECORD[20] = "Record\0";
	char text_PLAY[20] = "Play\0";
	char text_ECHO[20] = "De-noise\0";
	char text_erase[10] = "      \0";

	/* output text message to the LCD */
	alt_up_character_lcd_set_cursor_pos (lcd_dev, 0, 0);	// set LCD cursor location to top row
	alt_up_character_lcd_string (lcd_dev, text_top_LCD);
	alt_up_character_lcd_cursor_off (lcd_dev);				// turn off the LCD cursor 

	/* open the pixel buffer */
	pixel_buffer_dev = alt_up_pixel_buffer_dma_open_dev ("/dev/VGA_Pixel_Buffer");
	if ( pixel_buffer_dev == NULL)
		alt_printf ("Error: could not open pixel buffer device\n");
	else
		alt_printf ("Opened pixel buffer device\n");

	/* the following variables give the size of the pixel buffer */
	screen_x = 319; screen_y = 239;
	background_color = 0x0000;		// a dark grey color
	alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, 0, 0, screen_x, 
									  screen_y, background_color, 0); // fill the screen
	
	// draw a medium-blue box in the middle of the screen, using character buffer coordinates
	blue1_x1 = 40; blue1_x2 = 88; blue1_y1 = 104; blue1_y2 = 136;
	// character coords * 4 since characters are 4 x 4 pixel buffer coords (8 x 8 VGA coords)
	color = 0x187F;		// a medium blue color
	alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, blue1_x1, blue1_y1, blue1_x2, blue1_y2, color, 0);

	blue2_x1 = 128; blue2_x2 = 176; blue2_y1 = 104; blue2_y2 = 136;
	alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, blue2_x1, blue2_y1, blue2_x2, blue2_y2, color, 0);

	blue3_x1 = 216; blue3_x2 = 264; blue3_y1 = 104; blue3_y2 = 136;
	alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, blue3_x1, blue3_y1, blue3_x2, blue3_y2, color, 0);

	//draw new mouse
	mouse_color = 0xFFFF;
	draw_mouse(pixel_buffer_dev, center_x, center_y);

	/* output text message in the middle of the VGA monitor */
	char_buffer_dev = alt_up_char_buffer_open_dev ("/dev/VGA_Char_Buffer");
	if ( char_buffer_dev == NULL)
		alt_printf ("Error: could not open character buffer device\n");
	else
		alt_printf ("Opened character buffer device\n");

	alt_up_char_buffer_string (char_buffer_dev, text_RECORD, blue1_x1/4 + 3, blue1_y1/4 + 4);
	alt_up_char_buffer_string (char_buffer_dev, text_PLAY, blue2_x1/4 + 4, blue2_y1/4 + 4);
	alt_up_char_buffer_string (char_buffer_dev, text_ECHO, blue3_x1/4 + 2, blue3_y1/4 + 4);
	
	char_buffer_x = 79; char_buffer_y = 59;

	int mouse_pos_flag = 0;
	int denoise_flag = 0;
	/* this loops "bounces" the word ALTERA around on the VGA screen */
	while (1)
	{
	// wait to synchronize with timeout, which is set by the interval timer ISR
		if(packet_ready)
		{
			mouse_pos_flag = erase_mouse(pixel_buffer_dev, center_x, center_y, blue1_x1, blue1_y1, blue1_x2, blue1_y2, background_color, color);
			if (!mouse_pos_flag)
				mouse_pos_flag = erase_mouse(pixel_buffer_dev, center_x, center_y, blue2_x1, blue2_y1, blue2_x2, blue2_y2, background_color, color);
			if(!mouse_pos_flag)
				mouse_pos_flag = erase_mouse(pixel_buffer_dev, center_x, center_y, blue3_x1, blue3_y1, blue3_x2, blue3_y2, background_color, color);

			HEX_PS2(mouse_packet[0] & 0x50, mouse_packet[1], mouse_packet[0] & 0xA0, mouse_packet[2]);
			// Update mouse position
			center_x += (mouse_packet[0] & 0x10) ? (-256 + (int)mouse_packet[1]) : (int)mouse_packet[1];
			center_y -= (mouse_packet[0] & 0x20) ? (-256 + (int)mouse_packet[2]) : (int)mouse_packet[2];
			// Handle Boundries
			if(center_x > screen_x - 5)
				center_x = screen_x - 5;
			else if (center_x < 5)
				center_x = 5;
			if(center_y > screen_y - 5)
				center_y = screen_y - 5;
			else if (center_y < 5)
				center_y = 5;

			draw_mouse(pixel_buffer_dev, center_x, center_y);
			alt_up_parallel_port_write_data (up_dev.green_LEDs_dev, mouse_packet[0] & 0x7);
			//reset status
			packet_ready = 0;
			mouse_pos_flag = 0;
			// Click on bottons
			if((center_x + 5 <= blue1_x2 && center_x - 5 >= blue1_x1) &&
			   (center_y + 5 <= blue1_y2 && center_y - 5 >= blue1_y1) && (mouse_packet[0] & 0x1))
			{
				KEY_value = 0x2;
				denoise_flag = 0;
			}
			else if((center_x + 5 <= blue2_x2 && center_x - 5 >= blue2_x1) &&
			 		(center_y + 5 <= blue2_y2 && center_y - 5 >= blue2_y1) && (mouse_packet[0] & 0x1))
			{
				KEY_value = 0x4;
			}
			else if((center_x + 5 <= blue3_x2 && center_x - 5 >= blue3_x1) &&
					(center_y + 5 <= blue3_y2 && center_y - 5 >= blue3_y1) && (mouse_packet[0] & 0x1))
			{
				KEY_value = 0x8;
				if(!denoise_flag)
				{
					// filter_noise_sw();
					// filter_noise_others();
					denoise_flag = 1;
				}
			}
			//Check for Record, Play or De-noise
			if (KEY_value == 0x2)										
			{
				// reset the buffer index for recording
				buf_index_record = 0;
				// clear audio FIFOs
				alt_up_audio_reset_audio_core (audio_dev);
				// enable audio-in interrupts
				alt_up_audio_enable_read_interrupt (audio_dev);
			}
			else if (KEY_value == 0x4)								
			{
				// reset counter to start playback
				buf_index_play = 0;
				// clear audio FIFOs
				alt_up_audio_reset_audio_core (audio_dev);
				// enable audio-out interrupts
				alt_up_audio_enable_write_interrupt (audio_dev);
			}
			else if (KEY_value == 0x8)								
			{
				// reset counter to start playback
				buf_index_play = 0;
				// clear audio FIFOs
				alt_up_audio_reset_audio_core (audio_dev);
				// enable audio-out interrupts
				alt_up_audio_enable_write_interrupt (audio_dev);
			}
		}
		/* also, display any PS/2 data (from its interrupt service routine) on HEX displays */
		timeout = 0;
	}
}

/****************************************************************************************
 * Subroutine to show a string of HEX data on the HEX displays
 * Note that we are using pointer accesses for the HEX displays parallel port. We could
 * also use the HAL functions for these ports instead
****************************************************************************************/
void HEX_PS2(unsigned char b1x, unsigned char b2, unsigned char b1y, unsigned char b3)
{
	volatile int *HEX3_HEX0_ptr = (int *) 0x10000020;
	volatile int *HEX7_HEX4_ptr = (int *) 0x10000030;

	/* SEVEN_SEGMENT_DECODE_TABLE gives the on/off settings for all segments in 
	 * a single 7-seg display in the DE2 Media Computer, for the hex digits 0 - F */
	unsigned char seven_seg_decode_table[] = { 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 
		  									   0x7F, 0x67, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71 };
	unsigned char hex_segs[] = { 0, 0, 0, 0, 0, 0, 0, 0 };
	unsigned int shift_buffer;

	shift_buffer = (b1x << 24) | (b2 << 16) | (b1y << 8) | b3;
	
	hex_segs[0] = seven_seg_decode_table[b3 & 0xF];
	hex_segs[1] = seven_seg_decode_table[(b3 >> 4) & 0xF];
	hex_segs[2] = seven_seg_decode_table[(b1y >> 4) & 0x8];
	hex_segs[3] = seven_seg_decode_table[(b1y >> 5) & 0x1];
	hex_segs[4] = seven_seg_decode_table[b2 & 0xF];
	hex_segs[5] = seven_seg_decode_table[(b2 >> 4) & 0xF];
	hex_segs[6] = seven_seg_decode_table[(b1x >> 4) & 0x4];
	hex_segs[7] = seven_seg_decode_table[(b1x >> 4) & 0x1];

	/* drive the hex displays */
	*(HEX3_HEX0_ptr) = *(int *) (hex_segs);
	*(HEX7_HEX4_ptr) = *(int *) (hex_segs + 4);
}

int erase_mouse(alt_up_pixel_buffer_dma_dev *pixel_buffer_dev, int center_x, int center_y, int blue1_x1,
				  int blue1_y1, int blue1_x2, int blue1_y2, short background_color, short color) 
{
	int status = 0;
	if((center_x + 7 >= blue1_x1 && center_x <= blue1_x1) && (center_y + 15 <= blue1_y2 && center_y >= blue1_y1)) 
	{
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y, blue1_x1, center_y + 15, background_color, 0);
	    alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, blue1_x1, center_y, center_x + 7, center_y + 15, color, 0);
	    status = 1;
	}
	else if((center_x + 7 >= blue1_x2 && center_x <= blue1_x2) && (center_y + 15 <= blue1_y2 && center_y >= blue1_y1)) 
	{
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, blue1_x2, center_y, center_x + 7, center_y + 15, background_color, 0);
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y, blue1_x2, center_y + 15, color, 0);
		status = 1;
	}
	else if((center_x + 7 <= blue1_x2 && center_x >= blue1_x1) && (center_y + 15 >= blue1_y2 && center_y <= blue1_y2)) 
	{
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y, center_x + 7, blue1_y2, color, 0);
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, blue1_y2, blue1_x2, center_y + 15, background_color, 0);
		status = 1;
	}
	else if((center_x + 7 <= blue1_x2 && center_x >= blue1_x1) && (center_y + 15 >= blue1_y1 && center_y <= blue1_y1)) 
	{
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y , center_x + 7, blue1_y1, background_color, 0);
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, blue1_y1, blue1_x2, center_y + 15, color, 0);
		status = 1;
	}
	else if((center_x + 7 <= blue1_x2 && center_x >= blue1_x1) && (center_y + 15 <= blue1_y2 && center_y >= blue1_y1))
	{
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y, center_x + 7, center_y + 15, color, 0);
		status = 1;
	}
	else if((center_x + 7 >= blue1_x1 && center_x <= blue1_x1) && (center_y + 15 >= blue1_y1 && center_y <= blue1_y1) ) 
	{
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y, center_x + 7, center_y + 15, background_color, 0);
	    alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, blue1_x1, blue1_y1, center_x + 7, center_y + 15, color, 0);
	    status = 1;
	}
	else if((center_x + 7 >= blue1_x2 && center_x <= blue1_x2) && (center_y + 15 >= blue1_y1 && center_y <= blue1_y1) ) 
	{
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y, center_x + 7, center_y + 15, background_color, 0);
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y + 15, blue1_x2, blue1_y1, color, 0);
		status = 1;
	}
	else if((center_x + 7 >= blue1_x1 && center_x <= blue1_x1) && (center_y + 15 >= blue1_y2 && center_y <= blue1_y2) ) 
	{
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y, center_x + 7, center_y + 15, background_color, 0);
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, blue1_x1, blue1_y2, center_x + 15, center_y, color, 0);
		status = 1;
	}
	else if((center_x + 7 >= blue1_x2 && center_x <= blue1_x2) && (center_y + 15 >= blue1_y2 && center_y <= blue1_y2) ) 
	{
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y, center_x + 7, center_y + 15, background_color, 0);
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y, blue1_x2, blue1_y2, color, 0);
		status = 1;
	}
	else
		alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x, center_y, center_x + 7, center_y + 15, background_color, 0);

	return status;
}

void draw_mouse(alt_up_pixel_buffer_dma_dev *pixel_buffer_dev, int center_x, int center_y)
{
	short pixel_color;
	int i, j;
	for(i = 0; i < 16; i ++)
	{
		for(j = 0; j < 8; j++)
		{
			if(mouse_icon[i][j] != -1)
			{
				if(mouse_icon[i][j] == 0)
					pixel_color = 0x0000;
				else if(mouse_icon[i][j] == 1)
					pixel_color = 0xFFFF;
				alt_up_pixel_buffer_dma_draw_box (pixel_buffer_dev, center_x + j, center_y + i, center_x + j, center_y + i, pixel_color, 0);
			}
		}
	}
}
// Software filter functrion
void filter_noise_sw()
{
// float elapsed_time;
	double coeffs[64] = {-0.0019989013671875
				     	,-0.0050506591796875
				     	,-0.008331298828125
				     	,-0.0105438232421875
				     	,-0.0092926025390625
				     	,-0.0046539306640625
				     	, 0.0021209716796875
				     	, 0.0072174072265625
				     	, 0.0078125
				     	, 0.0027618408203125
				     	,-0.004852294921875
				     	,-0.0102081298828125
				     	,-0.008819580078125
				     	,-0.0006866455078125
				     	, 0.0095977783203125
				     	, 0.0146331787109375
				     	, 0.009735107421875
				     	,-0.0036163330078125
				     	,-0.0170440673828125
				     	,-0.0205535888671875
				     	,-0.009063720703125
				     	, 0.01220703125
				     	, 0.0296478271484375
				     	, 0.028717041015625
				     	, 0.00469970703125
				     	,-0.031494140625
				     	,-0.056121826171875
				     	,-0.0446319580078125
				     	, 0.013763427734375
				     	, 0.106964111328125
				     	, 0.2028656005859375
				     	, 0.2635040283203125
				     	, 0.2635040283203125
				     	, 0.2028656005859375
				     	, 0.106964111328125
				     	, 0.013763427734375
				     	,-0.0446319580078125
				     	,-0.056121826171875
				     	,-0.031494140625
				     	, 0.00469970703125
				     	, 0.028717041015625
				     	, 0.0296478271484375
				     	, 0.01220703125
				     	,-0.009063720703125
				     	,-0.0205535888671875
				     	,-0.0170440673828125
				     	,-0.0036163330078125
				     	, 0.009735107421875
				     	, 0.0146331787109375
				     	, 0.0095977783203125
				     	,-0.0006866455078125
				     	,-0.008819580078125
				     	,-0.0102081298828125
				     	,-0.004852294921875
				     	, 0.0027618408203125
				     	, 0.0078125
				     	, 0.0072174072265625
				     	, 0.0021209716796875
				     	,-0.0046539306640625
				     	,-0.0092926025390625
				     	,-0.0105438232421875
				     	,-0.008331298828125
				     	,-0.0050506591796875
				     	,-0.0019989013671875
						};
	volatile float l_buf_new[BUF_SIZE];
	volatile double el_buf_new[BUF_SIZE];
	int i, j, k;
	// alt_timestamp_start();
	// float t1 = ((float) alt_timestamp()) / ((float)alt_timestamp_freq());
	for(k = 0; k < BUF_SIZE; k++)
		l_buf_new[k] = ((float)(l_buf[k] >> 8)) * 0.00000011920929; // * 0.5 ^ 23
	for(i = 0; i < BUF_SIZE; i++)
	{
		double temp = 0.0;
		for(j = i; j > i - 64; j--)
		{
			if (j < 0)
				break;
			temp += l_buf_new[j] * coeffs[i - j];
		}
		el_buf_new[i] = temp;
	}
	for (k = 0; k < BUF_SIZE; k++)
	{
		el_buf[k] = ((int)(el_buf_new[k] * 1073741824.0)) >> 7;
		er_buf[k] = el_buf[k];
	}
	// float t2 = ((float) alt_timestamp()) / ((float)alt_timestamp_freq());
	// printf("Elapsed time with %f",t2 - t1);
}

void filter_noise_others()
{
  double coeffs[64] = {-0.0019989013671875
  				      ,-0.0050506591796875
  				      ,-0.008331298828125
  				      ,-0.0105438232421875
  				      ,-0.0092926025390625
  				      ,-0.0046539306640625
  				      , 0.0021209716796875
  				      , 0.0072174072265625
  				      , 0.0078125
  				      , 0.0027618408203125
  				      ,-0.004852294921875
  				      ,-0.0102081298828125
  				      ,-0.008819580078125
  				      ,-0.0006866455078125
  				      , 0.0095977783203125
  				      , 0.0146331787109375
  				      , 0.009735107421875
  				      ,-0.0036163330078125
  				      ,-0.0170440673828125
  				      ,-0.0205535888671875
  				      ,-0.009063720703125
  				      , 0.01220703125
  				      , 0.0296478271484375
  				      , 0.028717041015625
  				      , 0.00469970703125
  				      ,-0.031494140625
  				      ,-0.056121826171875
  				      ,-0.0446319580078125
  				      , 0.013763427734375
  				      , 0.106964111328125
  				      , 0.2028656005859375
  				      , 0.2635040283203125
  				      , 0.2635040283203125
  				      , 0.2028656005859375
  				      , 0.106964111328125
  				      , 0.013763427734375
  				      ,-0.0446319580078125
  				      ,-0.056121826171875
  				      ,-0.031494140625
  				      , 0.00469970703125
  				      , 0.028717041015625
  				      , 0.0296478271484375
  				      , 0.01220703125
  				      ,-0.009063720703125
  				      ,-0.0205535888671875
  				      ,-0.0170440673828125
  				      ,-0.0036163330078125
  				      , 0.009735107421875
  				      , 0.0146331787109375
  				      , 0.0095977783203125
  				      ,-0.0006866455078125
  				      ,-0.008819580078125
  				      ,-0.0102081298828125
  				      ,-0.004852294921875
  				      , 0.0027618408203125
  				      , 0.0078125
  				      , 0.0072174072265625
  				      , 0.0021209716796875
  				      ,-0.0046539306640625
  				      ,-0.0092926025390625
  				      ,-0.0105438232421875
  				      ,-0.008331298828125
  				      ,-0.0050506591796875
  				      ,-0.0019989013671875
					  };
	alt_timestamp_start();
    float r_cast[BUF_SIZE], l_cast[BUF_SIZE];
    double r_mid[BUF_SIZE], l_mid[BUF_SIZE];
	float t1 = ((float) alt_timestamp()) / ((float)alt_timestamp_freq());
	int i;
    for(i = 0; i < BUF_SIZE; i++)
	{
    	r_buf[i] = (r_buf[i] >> 8);
    	r_cast[i] = (float)(r_buf[i]);
    	r_cast[i] = r_cast[i] / 8388608.0;
    	l_buf[i] = (l_buf[i] >> 8);
    	l_cast[i] = (float)(l_buf[i]);
    	l_cast[i] = l_cast[i] / 8388608.0;
    }
    for(i = 0; i < BUF_SIZE; i++)
	{
    	int j;
    	double temp1, temp2;
    	temp1 = 0.0;
    	temp2 = 0.0;
    	for (j = i; j > i - 64; j--)
		{
    		if (j < 0)
    			break;
    		temp1 += l_cast[j] * coeffs[(i - j)];
    		temp2 += r_cast[j] * coeffs[(i - j)];
    	}
    	l_mid[i] = temp1;
    	r_mid[i] = temp2;
  	}
    double temp1,temp2;
    int temp_int1, temp_int2;
    for(i = 0; i < BUF_SIZE; i++)
	{
    	temp1 = l_mid[i] * 1073741824.0;
    	temp2 = r_mid[i] * 1073741824.0;
    	temp_int1 = (int)temp1;
    	temp_int2 = (int)temp2;
    	el_buf[i] = temp_int1 >> 7;
    	er_buf[i] = temp_int2 >> 7;
  }
	float t2 = ((float) alt_timestamp()) / ((float)alt_timestamp_freq());
	printf("Elapsed time with %f",t2 - t1);
}