# Licence and attribution notice

Project: STA4028Z Portfolio Theory, Assignment 2 (Backtesting a Black-Litterman Portfolio)
Version: PT_A2_2026_FRNBEN003_v1.0
Author: Benjamin Franco (FRNBEN003)

Part II of this assignment reuses ideas, and some functions, from the public repository by
Tim Gebbie (lecturer, STA4028Z, University of Cape Town):

- https://github.com/timgebbie/STA4028Z-PortfolioTheory-Code
- Code: BSD 3-Clause licence (full text below).
- Data: Creative Commons Attribution 4.0 (CC BY 4.0).

## Files copied unchanged from the Gebbie repository

Source: branch `main`, commit `a8b83f4485a2bcfa4fea25ef5bd7512fa83e93a9`, copied on 2026-10-14.
Licence of each file: BSD-3-Clause. Each file is a byte-for-byte copy; none has been edited.

| Path in his repository | Path in this project | SHA-256 |
| --- | --- | --- |
| `functions/data/readRawMarketWorkbook.m` | `functions/data/readRawMarketWorkbook.m` | `5f760f76fdd77e180605e5c3e43d507514724b4943d18be3c442d42683a1565a` |
| `functions/data/prepareCourseData.m` | `functions/data/prepareCourseData.m` | `713dd78f1ee815a6a2b78c9dd427bc3c969a7658198da43032dab014b945e195` |
| `functions/data/computeAssetReturns.m` | `functions/data/computeAssetReturns.m` | `c11fb46c2bebf45c13ed1ffe90fc0b5c93a72ad842528b1543dabd6b007f3a3d` |
| `functions/data/sha256File.m` | `functions/data/sha256File.m` | `38c7a224994ca7f6ff6e9c0fbff7037f27f7542fc14380e1fcde5d21b5b8c854` |
| `functions/portfolio/blackLittermanPosterior.m` | `functions/portfolio/blackLittermanPosterior.m` | `9161f185443a1dc1f02bd9497b72617d37b46a7cbea2ff26aeb50a2fb21cc0a5` |

Each copied file keeps its original header and its original `SPDX-License-Identifier: BSD-3-Clause`
line. `sha256File.m` has no SPDX line in the original, and none was added.

All other files in this project were written by Benjamin Franco. They call the functions above
(for example `loadA2Data.m` calls `prepareCourseData.m`).

## BSD 3-Clause licence of the copied code

    BSD 3-Clause License
    
    Copyright (c) 2026, Timothy Gebbie and contributors
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    1. Redistributions of source code must retain the above copyright notice, this
       list of conditions and the following disclaimer.
    
    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution.
    
    3. Neither the name of the copyright holder nor the names of its
       contributors may be used to endorse or promote products derived from
       this software without specific prior written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
