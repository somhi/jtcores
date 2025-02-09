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
    Date: 11-11-2021 */

module jttrack_snd(
    input               rst,
    input               clk,
    input               snd_cen,    // 3.5MHz
    input               psg_cen,    // 1.7MHz
    // ROM
    output      [13:0]  rom_addr,
    output reg          rom_cs,
    input       [ 7:0]  rom_data,
    input               rom_ok,
    // From main CPU
    input       [ 7:0]  main_dout,
    input               m2s_data,
    input               m2s_irq,
    // Sound
    output     [15:0]   pcm_addr, // only 8kB ROMs actually used
    input      [ 7:0]   pcm_data,
    input               pcm_ok,

    // sound output
    output signed [10:0] psg,
    output signed [ 9:0] vlm,
    output signed [ 7:0] rdac,
    output        [ 1:0] vlm_rcen,
    output        [ 1:0] psg_rcen,
    output               rdac_rcen,
    output        [ 7:0] debug_view
);

// Road Fighter: sch. has bit A10 as a jumper to either ground or VDD
// Track'n Field has A10 connected to the CPU, so RAM_AW must be set to 11 for it
parameter RAM_AW=11;

localparam CNTW=13;

reg  [ 7:0] din;
wire [ 7:0] ram_dout, latch;
reg         ram_cs;
wire        mreq_n;
wire [15:0] A;
reg  [ 3:0] cap_en;
reg         vlm_rst, vlm_st, vlm_sel;
wire        vlm_bsy;
reg         psgdata_cs, vlm_data_cs, vlm_ctrl_cs;
reg         latch_cs, cnt_cs, rdac_cs, psg_cs, cap_cs, vlm_rd_cs;
wire [CNTW-1:0] cnt;

assign debug_view = {4'd0, cap_en};

always @(posedge clk, posedge rst) begin
    if( rst ) begin
        cap_en   <= 0;
        vlm_rst  <= 1;
        vlm_st   <= 0;
        vlm_sel  <= 0;
    end else begin
        if( vlm_ctrl_cs ) { vlm_rst, vlm_st, vlm_sel } <= A[9:7];
        if( cap_cs ) cap_en <= A[6:3];
    end
end

always @* begin
    rom_cs      = 0;
    ram_cs      = 0;
    latch_cs    = 0;
    cnt_cs      = 0;
    vlm_data_cs = 0;
    vlm_ctrl_cs = 0;
    rdac_cs     = 0;
    psgdata_cs  = 0;
    psg_cs      = 0;
    cap_cs      = 0;
    vlm_rd_cs   = 0;
    if( !mreq_n ) begin
        case(A[15:13])
            0,1: rom_cs    = 1;
            2: ram_cs      = 1; // 4000
            3: latch_cs    = 1; // 6000
            4: cnt_cs      = 1; // 8000
            5: psgdata_cs  = 1; // A000
            6: psg_cs      = 1; // C000
            7: case( A[2:0] )
                0: rdac_cs    = 1;  // E000
                1: cap_cs     = 1;  // E001
                2: vlm_rd_cs  = 1;  // E002
                3: vlm_ctrl_cs= 1;  // E003
                4: vlm_data_cs= 1;  // E003
                default:;
            endcase
            default:;
        endcase
    end
end

always @(posedge clk) begin
    din  <= rom_cs   ? rom_data :
            ram_cs   ? ram_dout :
            cnt_cs   ? { 4'hf, cnt[CNTW-1:CNTW-4] } :
            vlm_rd_cs? { 3'b111, vlm_bsy, 4'hf } :
            latch_cs ? latch    :
            8'hff;
end

jtsbaskt_snd_dev #( .RAM_AW(RAM_AW),.CNTW(CNTW)) u_dev(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .snd_cen    ( snd_cen   ),    // 3.5MHz
    .psg_cen    ( psg_cen   ),    // 1.7MHz
    // Sound CPU
    .A          ( A         ),
    .din        ( din       ),
    .ram_dout   ( ram_dout  ),
    .mreq_n     ( mreq_n    ),
    // Misc
    .ram_cs     ( ram_cs    ),
    .cnt_cs     ( cnt_cs    ),
    .psg_cs     ( psg_cs    ),
    .psgdata_cs ( psgdata_cs),
    .rdac_cs    ( rdac_cs   ),
    .vlm_data_cs(vlm_data_cs),
    .vlm_bsy    ( vlm_bsy   ),
    .cap_en     ( cap_en    ), // Enable capacitors
    .cnt        ( cnt       ),
    .vlm_st     ( vlm_st    ),
    .vlm_rst    ( vlm_rst   ),
    .vlm_sel    ( vlm_sel   ),
    // ROM
    .rom_addr   ( rom_addr  ),
    .rom_cs     ( rom_cs    ),
    .rom_data   ( rom_data  ),
    .rom_ok     ( rom_ok    ),
    // From main CPU
    .main_dout  ( main_dout ),
    .m2s_data   ( m2s_data  ),
    .m2s_irq    ( m2s_irq   ),
    .latch      ( latch     ),
    // Sound
    .pcm_addr   ( pcm_addr  ), // only 8kB ROMs actually used
    .pcm_data   ( pcm_data  ),
    .pcm_ok     ( pcm_ok    ),

    .psg        ( psg       ),
    .vlm        ( vlm       ),
    .rdac       ( rdac      ),
    .vlm_rcen   ( vlm_rcen  ),
    .psg_rcen   ( psg_rcen  ),
    .rdac_rcen  ( rdac_rcen ),
    .debug_bus  ( 8'd0      )
);


endmodule
