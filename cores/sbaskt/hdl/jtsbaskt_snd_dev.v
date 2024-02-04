/*  This file is part of JTCORES.
    JTCORES program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTCORES program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTCORES.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 20-3-2022 */

module jtsbaskt_snd_dev #(
    // Road Fighter: sch. has bit A10 as a jumper to either ground or VDD
    // Track'n Field has A10 connected to the CPU, so RAM_AW must be set to 11 for it
    parameter RAM_AW=10, CNTW=11
) (
    input               rst,
    input               clk,
    input               snd_cen,    // 3.5MHz
    input               psg_cen,    // 1.7MHz
    // Sound CPU
    output      [15:0]  A,
    input       [ 7:0]  din,
    output      [ 7:0]  ram_dout,
    output              mreq_n,
    // Misc
    input               ram_cs,
    input               cnt_cs,
    input               psg_cs,
    input               psgdata_cs,
    input               vlm_data_cs,
    input               rdac_cs,
    output              vlm_bsy,
    input               vlm_rst,
    input               vlm_st,
    input               vlm_sel,
    input       [ 3:0]  cap_en, // Enable capacitors
    output reg [CNTW-1:0] cnt,
    // ROM
    output      [13:0]  rom_addr,
    input               rom_cs,
    input       [ 7:0]  rom_data,
    input               rom_ok,
    // From main CPU
    input       [ 7:0]  main_dout,
    input               m2s_data,
    input               m2s_irq,
    output reg  [ 7:0]  latch,
    // Sound
    output     [15:0]   pcm_addr, // only 8kB ROMs actually used
    input      [ 7:0]   pcm_data,
    input      [ 7:0]   debug_bus,
    input               pcm_ok,

    output signed [15:0] snd,
    output               sample,
    output               peak
);

localparam [7:0] GAIN_PSG  = 8'h18;
localparam [7:0] GAIN_VLM  = 8'h18;
localparam [7:0] GAIN_RDAC = 8'h08;

reg  [ 7:0] psg_data, vlm_data, rdac;
wire [ 7:0] vlm_mux, dout;
wire        irq_ack, int_n;
wire        vlm_ceng, vlm_me_b;
wire [10:0] psg_snd;
wire        iorq_n, m1_n;
wire        rdy1;
wire signed [10:0] psg_pre;
wire signed [ 9:0] vlm_snd, vlm_pre;
wire signed [ 7:0] rdac_snd, rdac_s;

assign vlm_mux = ~vlm_sel ? vlm_data :
               ~vlm_me_b ? pcm_data : 8'hff;
assign pcm_addr[15:13]=0;
assign irq_ack = ~iorq_n & ~m1_n;
assign vlm_ceng = snd_cen & ( vlm_me_b | pcm_ok );
assign rom_addr = A[13:0];
assign sample   = psg_cen;

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        latch    <= 0;
        psg_data <= 0;
        cnt      <= 0;
    end else begin
        if( psg_cen     ) cnt<=cnt+1'd1;
        if( m2s_data    ) latch <= main_dout;
        if( psgdata_cs  ) psg_data <= dout;
        if( vlm_data_cs ) vlm_data <= dout;
        if( rdac_cs     ) rdac <= dout;
    end
end

jt89 u_psg(
    .rst    ( rst           ),
    .clk    ( clk           ),
    .clk_en ( psg_cen       ),
    .wr_n   ( rdy1          ),
    .cs_n   ( ~psg_cs       ),
    .din    ( psg_data      ),
    .sound  ( psg_pre       ),
    .ready  ( rdy1          )
);

// Road Fighter/Super Basket board have software controlled RC filters
// with fc = 220Hz for the DAC
// and  fc = 720Hz for the JT89/VLM5030
// the filter below do not try to be exact (yet)
// but they capture the variable sound filtering in the game
jtframe_pole #(.WS(11)) u_rc_psg(
    .rst        ( rst       ),
    .clk        ( clk       ),
    // .a       ( debug_bus[4:0] ),
    .a          ({{3{cap_en[2]}},2'd0}),
    .sample     ( psg_cen   ),
    .sin        ( psg_pre   ),
    .sout       ( psg_snd   )
);

jtframe_pole #(.WS(8)) u_rc_dac(
    .rst        ( rst       ),
    .clk        ( clk       ),
    // .a       ( debug_bus[3:0] ),
    .a          ( {4{cap_en[1]}} ),
    .sample     ( cnt[6]    ), // 14 kHz
    .sin        ( rdac_s    ),
    .sout       ( rdac_snd  )
);

jtframe_pole #(.WS(10)) u_vlm_psg(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .a          ({{3{cap_en[0]}},2'd0}),
    .sample     ( psg_cen   ),
    .sin        ( vlm_pre   ),
    .sout       ( vlm_snd   )
);

`ifndef NOVLM
wire [ 2:0] pcm_nc;
/* verilator lint_off PINMISSING */
vlm5030_gl u_vlm(
    .i_rst   ( vlm_rst      ),
    .i_clk   ( clk          ),
    .i_oscen ( vlm_ceng     ),
    .i_start ( vlm_st       ),
    .i_vcu   ( 1'b0         ),
    .i_tst1  ( 1'b0         ),
    .o_tst2  (              ),
    .o_tst4  (              ),
    .i_d     ( vlm_mux      ),
    .o_a     ( { pcm_nc, pcm_addr[12:0] } ),
    .o_me_l  ( vlm_me_b     ),
    .o_mte   (              ),
    .o_bsy   ( vlm_bsy      ),

    .o_dao   (              ),
    .o_audio ( vlm_pre      )
);
/* verilator lint_on PINMISSING */
`else
    reg busy_dummy=0;
    reg cnt_csl;

    assign vlm_bsy = busy_dummy;
    assign pcm_addr = 0;
    assign vlm_snd  = 0;
    assign vlm_me_b = 0;

    always @(posedge clk) begin
        cnt_csl <= cnt_cs;
        if( cnt_cs && !cnt_csl ) busy_dummy <= ~busy_dummy;
    end
`endif

jtframe_dcrm #(.SW(8)) u_dcrm(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .sample ( cnt[6]    ),  // 14 kHz
    .din    ( rdac      ),
    .dout   ( rdac_s    )
);

jtframe_mixer #(.W0(11),.W1(10),.W2(8)) u_mixer(
    .rst    ( rst       ),
    .clk    ( clk       ),
    .cen    ( psg_cen   ),
    // input signals
    .ch0    ( psg_snd   ),
    .ch1    ( vlm_snd   ),
    .ch2    ( rdac_snd  ),
    .ch3    ( 16'd0     ),
    // gain for each channel in 4.4 fixed point format
    .gain0  ( GAIN_PSG  ),
    .gain1  ( GAIN_VLM  ),
    .gain2  ( GAIN_RDAC ),
    .gain3  ( 8'h00     ),
    .mixed  ( snd       ),
    .peak   ( peak      )
);

jtframe_ff u_irq(
    .rst      ( rst         ),
    .clk      ( clk         ),
    .cen      ( 1'b1        ),
    .din      ( 1'b1        ),
    .q        (             ),
    .qn       ( int_n       ),
    .set      (             ),
    .clr      ( irq_ack     ),
    .sigedge  ( m2s_irq     )
);

/* verilator tracing_off */

jtframe_sysz80 #(.RAM_AW(RAM_AW)) u_cpu(
    .rst_n      ( ~rst        ),
    .clk        ( clk         ),
    .cen        ( snd_cen     ),
    .cpu_cen    (             ),
    .int_n      ( int_n       ),
    .nmi_n      ( 1'b1        ),
    .busrq_n    ( 1'b1        ),
    .m1_n       ( m1_n        ),
    .mreq_n     ( mreq_n      ),
    .iorq_n     ( iorq_n      ),
    .rd_n       (             ),
    .wr_n       (             ),
    .rfsh_n     (             ),
    .halt_n     (             ),
    .busak_n    (             ),
    .A          ( A           ),
    .cpu_din    ( din         ),
    .cpu_dout   ( dout        ),
    .ram_dout   ( ram_dout    ),
    // manage access to ROM data from SDRAM
    .ram_cs     ( ram_cs      ),
    .rom_cs     ( rom_cs      ),
    .rom_ok     ( rom_ok      )
);

endmodule
