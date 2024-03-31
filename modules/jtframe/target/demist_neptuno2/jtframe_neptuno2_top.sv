module jtframe_neptuno2_top (
	input         CLOCK_50,
	input         KEY0,
	input         KEY1,
	output        LED,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

	output [12:0] SDRAM_A,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nWE,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nCS,
	output  [1:0] SDRAM_BA,
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	
	output        SD_CS,
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	
	// inout 		  PS2_KEYBOARD_CLK,
	// inout	      PS2_KEYBOARD_DAT,
	// inout	      PS2_MOUSE_CLK,
	// inout	      PS2_MOUSE_DAT,
	
    output        JOY_CLK,
	output        JOY_LOAD,
	input         JOY_DATA,
	output        JOY_SEL,
	
	output        AUDIO_L,
	output        AUDIO_R,

	output        I2S_BCK,
	output        I2S_LRCK,
	output        I2S_DATA,

	input         UART_RX,
	output        UART_TX
);

wire reset_n;
wire SPI_SCK,SPI_DO,SPI_DI,SPI_SS2,SPI_SS3,SPI_SS4,CONF_DATA0;

`ifdef USE_PLL_50_27
wire CLOCK_27;
wire pll_lock;
pll_50_27 u_pll_50_27 (
	.inclk0 ( CLOCK_50 ),
	.c0     ( CLOCK_27 ),
	.locked ( pll_lock )
);
`endif

wire ps2_keyboard_clk_in = PS2_KEYBOARD_CLK;
wire ps2_keyboard_clk_out;
wire ps2_keyboard_dat_in = PS2_KEYBOARD_DAT ;
wire ps2_keyboard_dat_out;
assign PS2_KEYBOARD_CLK = !ps2_keyboard_clk_out ? 1'b0 : 1'bZ;
assign PS2_KEYBOARD_DAT = !ps2_keyboard_dat_out ? 1'b0 : 1'bZ;

wire ps2_mouse_clk_in = PS2_MOUSE_CLK;
wire ps2_mouse_clk_out;
wire ps2_mouse_dat_in = PS2_MOUSE_DAT;
wire ps2_mouse_dat_out;
assign PS2_MOUSE_CLK = !ps2_mouse_clk_out ? 1'b0 : 1'bZ;
assign PS2_MOUSE_DAT = !ps2_mouse_dat_out ? 1'b0 : 1'bZ;


wire joy1up,joy1down,joy1left,joy1right,joy1fire1,joy1fire2;
wire joy2up,joy2down,joy2left,joy2right,joy2fire1,joy2fire2;
wire [5:0] joy1_bus, joy2_bus, intercept_joy;
wire [7:0] joy1, joy2;

joydecoder_neptuno joydecoder
(
	.clk_i        (CLOCK_50),
	.joy_data_i   (JOY_DATA),
	.joy_clk_o    (JOY_CLK),
	.joy_load_o   (JOY_LOAD),

	.joy1_up_o    (joy1up),
	.joy1_down_o  (joy1down),
	.joy1_left_o  (joy1left),
	.joy1_right_o (joy1right),
	.joy1_fire1_o (joy1fire1),
	.joy1_fire2_o (joy1fire2),

	.joy2_up_o    (joy2up),
	.joy2_down_o  (joy2down),
	.joy2_left_o  (joy2left),
	.joy2_right_o (joy2right),
	.joy2_fire1_o (joy2fire1),
	.joy2_fire2_o (joy2fire2) 
);

// osd joystick
assign joy1 ={2'b11,joy1fire2,joy1fire1,joy1right,joy1left,joy1down,joy1up};
assign joy2 ={2'b11,joy2fire2,joy2fire1,joy2right,joy2left,joy2down,joy2up};

// Core direct joystick
assign joy1_bus ={joy1fire2,joy1fire1,joy1up,joy1down,joy1left,joy1right};
assign joy2_bus ={joy2fire2,joy2fire1,joy2up,joy2down,joy2left,joy2right};


// Joystick intercept signal
assign intercept_joy = intercept ? 6'b111111 : 6'b000000;
assign JOY_SEL       = intercept ? 1'b1 : joy_select_o;

wire [15:0] dac_l, dac_r;

// I2S audio
audio_top  audio_i2s 
(
	.clk_50MHz (CLOCK_50),
	.dac_MCLK  (        ),
	.dac_SCLK  (I2S_BCLK),
	.dac_SDIN  (I2S_DATA),
	.dac_LRCK  (I2S_LRCLK),
	.L_data    (dac_l),
	.R_data    (dac_r)
);


////////// MIST GUEST TOP MODULE //////////

mist_top guest
(
 	.CLOCK_27	({CLOCK_50,CLOCK_50}),
	.LED		(act_led),

	.SDRAM_DQ	(SDRAM_DQ),
	.SDRAM_A	(SDRAM_A),
	.SDRAM_DQML	(SDRAM_DQML),
	.SDRAM_DQMH	(SDRAM_DQMH),
	.SDRAM_nWE	(SDRAM_nWE),
	.SDRAM_nCAS	(SDRAM_nCAS),
	.SDRAM_nRAS	(SDRAM_nRAS),
	.SDRAM_nCS	(SDRAM_nCS),
	.SDRAM_BA	(SDRAM_BA),
	.SDRAM_CLK	(SDRAM_CLK),
	.SDRAM_CKE	(SDRAM_CKE),

	.SPI_DO		(SPI_DO),     
	.SPI_DI		(SPI_DI),     
	.SPI_SCK	(SPI_SCK),    
	.SPI_SS2	(SPI_SS2),    
	.SPI_SS3	(SPI_SS3),    
	.SPI_SS4	(SPI_SS4),    
	.CONF_DATA0	(CONF_DATA0), 

	.VGA_HS		(VGA_HS),
	.VGA_VS		(VGA_VS),
	.VGA_R		(VGA_R),
	.VGA_G		(VGA_G),
	.VGA_B		(VGA_B),	

	.JOY1 	    (joy1_bus || intercept_joy),   // Block joystick when OSD is active
	.JOY2 	    (joy2_bus || intercept_joy),   // Block joystick when OSD is active
	.JOY_SELECT (joy_select_o),

	.DAC_L      (dac_l),
	.DAC_R      (dac_r),
	.AUDIO_L	(AUDIO_L),
	.AUDIO_R	(AUDIO_R)

	// .OSD_EN	    (osd_en)

);

wire act_led;
assign LED = ~act_led;


//////////    SUBSTITUTE MCU    //////////

wire rs232_rxd, rs232_txd;
wire intercept;
wire spi_fromguest;

// Pass internal signals to external SPI interface
assign SD_SCK = SPI_SCK;
assign SPI_DO = ~SPI_SS4 ? SD_MISO : 1'bZ;  // to guest
assign spi_fromguest = SPI_DO;  			// to control CPU

substitute_mcu #(
	.sysclk_frequency(500), 
	// .SPI_FASTBIT(3),				//needed if OSD hungs
	// .SPI_INTERNALBIT(2),			//needed if OSD hungs
	.debug("false"), 
	.jtag_uart("false")
) 
controller
(
 .clk          (CLOCK_50),
 .reset_in     (KEY0),			//reset_in  when 0
 .reset_out    (reset_n),		//reset_out  when 0
 
 .spi_miso     (SD_MISO),
 .spi_mosi     (SD_MOSI),
 .spi_clk      (SPI_SCK),
 .spi_cs       (SD_CS),
 .spi_fromguest(spi_fromguest),
 .spi_toguest  (SPI_DI),
 .spi_ss2      (SPI_SS2),
 .spi_ss3      (SPI_SS3),
 .spi_ss4      (SPI_SS4),
 .conf_data0   (CONF_DATA0),
 
 .ps2k_clk_in  (ps2_keyboard_clk_in),
 .ps2k_dat_in  (ps2_keyboard_dat_in),
 .ps2k_clk_out (ps2_keyboard_clk_out),
 .ps2k_dat_out (ps2_keyboard_dat_out),
 .ps2m_clk_in  (ps2_mouse_clk_in),
 .ps2m_dat_in  (ps2_mouse_dat_in),
 .ps2m_clk_out (ps2_mouse_clk_out),
 .ps2m_dat_out (ps2_mouse_dat_out),

 // Buttons
 .buttons	   ({31'h7FFFFFFF,KEY1}),		// 0=OSD_button

 // Joysticks
 .joy1         (joy1),
 .joy2         (joy2),

//  // UART
//  .rxd  			(rs232_rxd),
//  .txd  			(rs232_txd),

 // intercept=1 when OSD is on
 .intercept    (intercept)
);

endmodule
