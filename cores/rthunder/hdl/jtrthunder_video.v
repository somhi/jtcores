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
    Date: 15-3-2025 */

module jtrthunder_video(
    input             rst,
    input             clk,
    input             pxl_cen, pxl2_cen,

    output            lvbl, lhbl, hs, vs,
    output     [ 7:0] red, green, blue,
    // Dump MMR
    input      [ 5:0] ioctl_addr,
    output reg [ 7:0] ioctl_din,
    // Debug
    input      [ 3:0] gfx_en,
    input      [ 7:0] debug_bus
    // output reg [ 7:0] st_dout
);

jtshouse_vtimer u_vtimer(
    .clk        ( clk       ),
    .pxl_cen    ( pxl_cen   ),
    .vdump      ( vdump     ),
    .vrender    ( vrender   ),
    .vrender1   ( vrender1  ),
    .hdump      ( hdump     ),
    .lhbl       ( lhbl      ),
    .lvbl       ( lvbl      ),
    .hs         ( hs        ),
    .vs         ( vs        )
);

endmodule    