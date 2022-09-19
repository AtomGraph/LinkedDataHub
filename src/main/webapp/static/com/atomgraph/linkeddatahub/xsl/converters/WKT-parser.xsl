<?xml version="1.0" encoding="UTF-8"?>
<!-- This file was generated on Mon Sep 19, 2022 13:28 (UTC+02) by REx v5.55 which is Copyright (c) 1979-2022 by Gunther Rademacher <grd@gmx.net> -->
<!-- REx command line: wkt.ebnf -xslt -main -tree -ll 3 -backtrack -->

<xsl:stylesheet version="2.0"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:p="wkt"
                xmlns:ldh="https://w3id.org/atomgraph/linkeddatahub#">
  <!--~
   ! The index of the lexer state for accessing the combined
   ! (i.e. level > 1) lookahead code.
  -->
  <xsl:variable name="p:lk" as="xs:integer" select="1"/>

  <!--~
   ! The index of the lexer state for accessing the position in the
   ! input string of the begin of the token that has been consumed.
  -->
  <xsl:variable name="p:b0" as="xs:integer" select="2"/>

  <!--~
   ! The index of the lexer state for accessing the position in the
   ! input string of the end of the token that has been consumed.
  -->
  <xsl:variable name="p:e0" as="xs:integer" select="3"/>

  <!--~
   ! The index of the lexer state for accessing the code of the
   ! level-1-lookahead token.
  -->
  <xsl:variable name="p:l1" as="xs:integer" select="4"/>

  <!--~
   ! The index of the lexer state for accessing the position in the
   ! input string of the begin of the level-1-lookahead token.
  -->
  <xsl:variable name="p:b1" as="xs:integer" select="5"/>

  <!--~
   ! The index of the lexer state for accessing the position in the
   ! input string of the end of the level-1-lookahead token.
  -->
  <xsl:variable name="p:e1" as="xs:integer" select="6"/>

  <!--~
   ! The index of the lexer state for accessing the code of the
   ! level-2-lookahead token.
  -->
  <xsl:variable name="p:l2" as="xs:integer" select="7"/>

  <!--~
   ! The index of the lexer state for accessing the position in the
   ! input string of the begin of the level-2-lookahead token.
  -->
  <xsl:variable name="p:b2" as="xs:integer" select="8"/>

  <!--~
   ! The index of the lexer state for accessing the position in the
   ! input string of the end of the level-2-lookahead token.
  -->
  <xsl:variable name="p:e2" as="xs:integer" select="9"/>

  <!--~
   ! The index of the lexer state for accessing the code of the
   ! level-3-lookahead token.
  -->
  <xsl:variable name="p:l3" as="xs:integer" select="10"/>

  <!--~
   ! The index of the lexer state for accessing the position in the
   ! input string of the begin of the level-3-lookahead token.
  -->
  <xsl:variable name="p:b3" as="xs:integer" select="11"/>

  <!--~
   ! The index of the lexer state for accessing the position in the
   ! input string of the end of the level-3-lookahead token.
  -->
  <xsl:variable name="p:e3" as="xs:integer" select="12"/>

  <!--~
   ! The index of the lexer state for accessing the token code that
   ! was expected when an error was found.
  -->
  <xsl:variable name="p:error" as="xs:integer" select="13"/>

  <!--~
   ! The index of the lexer state for accessing the memoization
   ! of backtracking results.
  -->
  <xsl:variable name="p:memo" as="xs:integer" select="14"/>

  <!--~
   ! The index of the lexer state that points to the first entry
   ! used for collecting action results.
  -->
  <xsl:variable name="p:result" as="xs:integer" select="15"/>

  <!--~
   ! The codepoint to charclass mapping for 7 bit codepoints.
  -->
  <xsl:variable name="p:MAP0" as="xs:integer+" select="
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 28, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 3, 4, 3, 5, 0, 6, 6, 6, 6,
    6, 6, 6, 6, 6, 6, 0, 0, 0, 0, 0, 0, 0, 7, 0, 8, 9, 10, 11, 12, 13, 14, 0, 0, 15, 16, 17, 18, 19, 0, 20, 21, 22, 23, 24, 0, 0, 25, 26, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 27, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  "/>

  <!--~
   ! The codepoint to charclass mapping for codepoints below the surrogate block.
  -->
  <xsl:variable name="p:MAP1" as="xs:integer+" select="
    54, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58,
    58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 123, 90, 155, 117, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123,
    123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 123, 28, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 3, 4, 3, 5, 0, 6, 6, 6, 6, 6, 6, 6,
    6, 6, 6, 0, 0, 0, 0, 0, 0, 27, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 8, 9, 10, 11, 12,
    13, 14, 0, 0, 15, 16, 17, 18, 19, 0, 20, 21, 22, 23, 24, 0, 0, 25, 26, 0, 0, 0, 0, 0
  "/>

  <!--~
   ! The token-set-id to DFA-initial-state mapping.
  -->
  <xsl:variable name="p:INITIAL" as="xs:integer+" select="
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 521, 13, 14, 15, 16, 17, 18, 19
  "/>

  <!--~
   ! The DFA transition table.
  -->
  <xsl:variable name="p:TRANSITION" as="xs:integer+" select="
    465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 1364, 464, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465,
    465, 482, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 510, 465, 577, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465,
    465, 465, 1450, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 596, 708, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465,
    465, 465, 465, 631, 659, 681, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 1207, 1092, 465, 734, 1000, 465, 730, 465,
    465, 465, 465, 465, 465, 1007, 750, 466, 465, 553, 465, 608, 1545, 1608, 1635, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 1572, 465, 465, 465,
    465, 465, 465, 465, 465, 465, 465, 890, 769, 1525, 695, 913, 465, 798, 823, 1494, 1398, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 1137,
    465, 465, 842, 465, 465, 465, 465, 465, 465, 465, 859, 465, 465, 879, 465, 1468, 906, 826, 929, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 949, 465,
    465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 807, 967, 951, 465, 1023, 465, 465, 1054, 1066, 465, 465, 465, 465, 465, 465, 465, 1087, 615, 465,
    1108, 1173, 465, 1273, 1132, 465, 465, 465, 465, 465, 465, 465, 863, 1153, 1582, 1189, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465,
    561, 544, 1231, 782, 990, 465, 1289, 1590, 465, 465, 465, 465, 465, 465, 465, 714, 1198, 1071, 1406, 1305, 465, 1339, 465, 1255, 465, 465, 465, 465, 465,
    465, 465, 1380, 980, 1422, 1245, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 1440, 465, 1424, 1323, 1466, 1116, 643, 465, 465, 465,
    465, 465, 465, 465, 465, 465, 465, 580, 1314, 465, 1484, 1038, 465, 465, 465, 465, 465, 465, 465, 465, 465, 1510, 1527, 494, 533, 465, 753, 1684, 465, 1543,
    465, 465, 465, 465, 465, 465, 465, 1215, 465, 1642, 522, 1561, 843, 465, 1389, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 1606, 465, 465, 1264, 465,
    1624, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 1163, 465, 665, 1353, 465, 465, 465, 465, 465, 465, 465, 465, 465, 933, 465, 465, 465, 465, 465,
    465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 1521, 1525, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 1658, 1672, 465, 465,
    465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 465, 1536, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 1792, 0, 1792, 0, 0, 1792, 0, 1792,
    0, 0, 1792, 0, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5120, 0, 0, 20, 0, 20, 0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 0, 78, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 79,
    80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 81, 0, 0, 0, 0, 0, 0, 0, 0, 52, 0, 0, 5888, 0, 0, 0, 0, 0, 0, 46, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 71, 0, 0, 0, 0, 21, 0, 21, 0, 0, 0, 0, 0, 0, 21, 0, 0, 0, 0, 112, 113, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 53, 55, 0, 0, 0, 0, 0, 0, 0, 2070, 0,
    2070, 0, 0, 0, 0, 0, 0, 2070, 0, 0, 0, 0, 140, 0, 0, 0, 0, 0, 0, 0, 145, 0, 0, 0, 0, 0, 0, 2070, 2082, 2070, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 102, 0, 0, 0, 0,
    0, 0, 2082, 2094, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2094, 0, 0, 0, 62, 0, 0, 0, 0, 0, 0, 68, 0, 70, 0, 0, 0, 21, 0, 2082, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 39, 39,
    0, 0, 0, 43, 0, 0, 0, 150, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 120, 0, 0, 0, 27, 28, 28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 121, 0, 0, 23, 0, 0, 0, 0,
    35, 0, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 5376, 0, 0, 0, 0, 0, 0, 0, 0, 105, 0, 0, 0, 6144, 0, 0, 0, 0, 0, 0, 116, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 37, 37, 0, 41,
    0, 0, 0, 0, 3840, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2560, 0, 0, 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 123, 0, 29, 29, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 1280, 0, 0, 0, 73, 0, 0, 0, 0, 0, 0, 0, 0, 0, 87, 0, 0, 0, 0, 0, 23, 0, 23, 0, 23, 23, 0, 23, 23, 23, 23, 0, 3584, 0, 0, 0, 126, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 86, 0, 0, 0, 0, 0, 0, 0, 0, 4096, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1306, 0, 0, 0, 74, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 72, 0, 44, 0, 0, 0, 0, 0, 0, 0, 0, 0, 54, 0, 56, 0, 0, 0, 47, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 114, 0, 0, 117, 0, 0, 0, 0, 0, 0, 127, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 24, 25, 0, 0, 24, 25, 27, 0, 94, 0, 0, 0, 0, 0, 0, 0, 0, 0, 103, 0, 0, 106, 0, 0, 0, 125, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 136, 137, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 144, 0, 0, 0, 0, 151, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 69, 0, 0, 0, 0, 0, 30, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 88, 0, 0, 0, 0,
    0, 0, 76, 0, 0, 0, 0, 82, 0, 0, 0, 0, 0, 0, 0, 0, 129, 0, 131, 0, 0, 0, 0, 0, 0, 0, 0, 139, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 119, 0, 0, 0, 0, 0, 31, 31,
    0, 0, 0, 36, 0, 0, 1280, 0, 0, 0, 0, 0, 0, 65, 0, 1024, 0, 0, 0, 0, 0, 0, 0, 98, 0, 100, 0, 0, 0, 0, 0, 107, 0, 0, 0, 61, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 51, 0, 0, 0, 0, 0, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 0, 0, 38, 0, 0, 38, 0, 0, 42, 0, 0, 75, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 90, 0, 0, 0, 77, 0, 0, 0,
    83, 0, 0, 0, 0, 0, 0, 0, 0, 153, 0, 0, 0, 0, 0, 0, 0, 0, 0, 115, 0, 0, 0, 0, 0, 0, 0, 0, 128, 0, 0, 0, 132, 0, 0, 0, 0, 0, 3072, 0, 0, 0, 4608, 0, 0, 142,
    0, 0, 0, 0, 0, 0, 147, 0, 0, 95, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 84, 0, 0, 0, 0, 0, 0, 0, 0, 99, 0, 0, 0, 0, 104, 0, 0, 108, 124, 0, 0, 0, 0, 0, 0,
    0, 0, 130, 0, 0, 0, 134, 0, 0, 0, 111, 0, 0, 0, 0, 0, 0, 118, 0, 0, 0, 0, 0, 1536, 0, 1536, 0, 1536, 1536, 0, 1536, 1536, 1536, 1536, 0, 32, 32, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 141, 0, 0, 0, 0, 0, 0, 0, 0, 5632, 0, 0, 0, 0, 0, 0, 0, 0, 85, 0, 0, 0, 89, 0, 0, 0, 0, 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 91, 92, 45, 0, 0, 0, 48, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2304, 0, 2304, 0, 0, 2304, 0, 0, 0, 0, 109, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    122, 0, 0, 0, 110, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4864, 0, 0, 2816, 143, 0, 0, 0, 0, 0, 0, 33, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 35, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 57, 0, 0, 149, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 135, 0, 93, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97,
    0, 0, 0, 101, 0, 0, 0, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3328, 0, 0, 0, 0, 0, 0, 0, 59, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 146, 0, 0, 0,
    138, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 152, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 67, 0, 0, 0, 0, 0, 0, 768, 0, 0, 768, 768, 0, 0, 768, 768, 0, 0, 0, 768, 768,
    768, 0, 768, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4352, 0, 0, 0, 0, 0, 0, 0, 133, 0, 0, 0
  "/>

  <!--~
   ! The DFA-state to expected-token-set mapping.
  -->
  <xsl:variable name="p:EXPECTED" as="xs:integer+" select="
    39, 43, 47, 51, 55, 69, 59, 63, 68, 76, 64, 73, 77, 83, 75, 122, 85, 121, 89, 77, 94, 89, 77, 94, 90, 78, 101, 118, 79, 102, 76, 115, 76, 115, 98, 112, 109,
    106, 79, 4, 64, 128, 68, 132, 40, 320, 44, 324, 552, 2088, 448, 60, 556, 2092, 1576, 1580, 16776704, 16776708, 128, 2048, 16, 1536, 3584, 4096, 8192,
    507904, 3670016, 4194304, 12582912, 128, 128, 8, 512, 8388608, 128, 8, 512, 2048, 1024, 4096, 8192, 16384, 32768, 507904, 524288, 3145728, 8388608, 512,
    2048, 1048576, 2097152, 8388608, 512, 2048, 16384, 32768, 196608, 262144, 512, 1024, 4096, 32768, 65536, 131072, 262144, 2097152, 4096, 2097152, 4096,
    2097152, 4096, 32768, 2097152, 512, 4096, 32768, 131072, 262144, 2097152, 512, 2048, 1024, 4096, 8192, 507904, 524288
  "/>

  <!--~
   ! The token-string table.
  -->
  <xsl:variable name="p:TOKEN" as="xs:string+" select="
    '(0)',
    'END',
    'space',
    &quot;'EMPTY'&quot;,
    'z_m',
    &quot;'('&quot;,
    &quot;')'&quot;,
    'number',
    &quot;','&quot;,
    &quot;'CIRCULARSTRING'&quot;,
    &quot;'COMPOUNDCURVE'&quot;,
    &quot;'CURVEPOLYGON'&quot;,
    &quot;'GEOMETRYCOLLECTION'&quot;,
    &quot;'LINESTRING'&quot;,
    &quot;'MULTICURVE'&quot;,
    &quot;'MULTILINESTRING'&quot;,
    &quot;'MULTIPOINT'&quot;,
    &quot;'MULTIPOLYGON'&quot;,
    &quot;'MULTISURFACE'&quot;,
    &quot;'POINT'&quot;,
    &quot;'POLYGON'&quot;,
    &quot;'POLYHEDRALSURFACE'&quot;,
    &quot;'TIN'&quot;,
    &quot;'TRIANGLE'&quot;
  "/>

  <!--~
   ! Match next token in input string, starting at given index, using
   ! the DFA entry state for the set of tokens that are expected in
   ! the current context.
   !
   ! @param $input the input string.
   ! @param $begin the index where to start in input string.
   ! @param $token-set the expected token set id.
   ! @return a sequence of three: the token code of the result token,
   ! with input string begin and end positions. If there is no valid
   ! token, return the negative id of the DFA state that failed, along
   ! with begin and end positions of the longest viable prefix.
  -->
  <xsl:function name="p:match" as="xs:integer+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="begin" as="xs:integer"/>
    <xsl:param name="token-set" as="xs:integer"/>

    <xsl:variable name="result" select="$p:INITIAL[1 + $token-set]"/>
    <xsl:sequence select="p:transition($input, $begin, $begin, $begin, $result, $result mod 256, 0)"/>
  </xsl:function>

  <!--~
   ! The DFA state transition function. If we are in a valid DFA state, save
   ! it's result annotation, consume one input codepoint, calculate the next
   ! state, and use tail recursion to do the same again. Otherwise, return
   ! any valid result or a negative DFA state id in case of an error.
   !
   ! @param $input the input string.
   ! @param $begin the begin index of the current token in the input string.
   ! @param $current the index of the current position in the input string.
   ! @param $end the end index of the result in the input string.
   ! @param $result the result code.
   ! @param $current-state the current DFA state.
   ! @param $previous-state the  previous DFA state.
   ! @return a sequence of three: the token code of the result token,
   ! with input string begin and end positions. If there is no valid
   ! token, return the negative id of the DFA state that failed, along
   ! with begin and end positions of the longest viable prefix.
  -->
  <xsl:function name="p:transition">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="begin" as="xs:integer"/>
    <xsl:param name="current" as="xs:integer"/>
    <xsl:param name="end" as="xs:integer"/>
    <xsl:param name="result" as="xs:integer"/>
    <xsl:param name="current-state" as="xs:integer"/>
    <xsl:param name="previous-state" as="xs:integer"/>

    <xsl:choose>
      <xsl:when test="$current-state eq 0">
        <xsl:variable name="result" select="$result idiv 256"/>
        <xsl:variable name="end" select="if ($end gt string-length($input)) then string-length($input) + 1 else $end"/>
        <xsl:sequence select="
          if ($result ne 0) then
          (
            $result - 1,
            $begin,
            $end
          )
          else
          (
            - $previous-state,
            $begin,
            $current - 1
          )
        "/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="c0" select="(string-to-codepoints(substring($input, $current, 1)), 0)[1]"/>
        <xsl:variable name="c1" as="xs:integer">
          <xsl:choose>
            <xsl:when test="$c0 &lt; 128">
              <xsl:sequence select="$p:MAP0[1 + $c0]"/>
            </xsl:when>
            <xsl:when test="$c0 &lt; 55296">
              <xsl:variable name="c1" select="$c0 idiv 32"/>
              <xsl:variable name="c2" select="$c1 idiv 32"/>
              <xsl:sequence select="$p:MAP1[1 + $c0 mod 32 + $p:MAP1[1 + $c1 mod 32 + $p:MAP1[1 + $c2]]]"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="0"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="current" select="$current + 1"/>
        <xsl:variable name="i0" select="256 * $c1 + $current-state - 1"/>
        <xsl:variable name="i1" select="$i0 idiv 16"/>
        <xsl:variable name="next-state" select="$p:TRANSITION[$i0 mod 16 + $p:TRANSITION[$i1 + 1] + 1]"/>
        <xsl:sequence select="
          if ($next-state &gt; 255) then
            p:transition($input, $begin, $current, $current, $next-state, $next-state mod 256, $current-state)
          else
            p:transition($input, $begin, $current, $end, $result, $next-state, $current-state)
        "/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Recursively translate one 32-bit chunk of an expected token bitset
   ! to the corresponding sequence of token strings.
   !
   ! @param $result the result of previous recursion levels.
   ! @param $chunk the 32-bit chunk of the expected token bitset.
   ! @param $base-token-code the token code of bit 0 in the current chunk.
   ! @return the set of token strings.
  -->
  <xsl:function name="p:token">
    <xsl:param name="result" as="xs:string*"/>
    <xsl:param name="chunk" as="xs:integer"/>
    <xsl:param name="base-token-code" as="xs:integer"/>

    <xsl:sequence select="
      if ($chunk = 0) then
        $result
      else
        p:token
        (
          ($result, if ($chunk mod 2 != 0) then $p:TOKEN[$base-token-code] else ()),
          if ($chunk &lt; 0) then $chunk idiv 2 + 2147483648 else $chunk idiv 2,
          $base-token-code + 1
        )
    "/>
  </xsl:function>

  <!--~
   ! Calculate expected token set for a given DFA state as a sequence
   ! of strings.
   !
   ! @param $state the DFA state.
   ! @return the set of token strings
  -->
  <xsl:function name="p:expected-token-set" as="xs:string*">
    <xsl:param name="state" as="xs:integer"/>

    <xsl:if test="$state > 0">
      <xsl:for-each select="0 to 0">
        <xsl:variable name="i0" select=". * 153 + $state - 1"/>
        <xsl:variable name="i1" select="$i0 idiv 4"/>
        <xsl:sequence select="p:token((), $p:EXPECTED[$i0 mod 4 + $p:EXPECTED[$i1 + 1] + 1], . * 32 + 1)"/>
      </xsl:for-each>
    </xsl:if>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production geometrycollection_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-geometrycollection_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(19, $input, $state)"/>  <!-- space | 'CIRCULARSTRING' | 'COMPOUNDCURVE' | 'CURVEPOLYGON' |
                                                                                         'GEOMETRYCOLLECTION' | 'LINESTRING' | 'MULTICURVE' |
                                                                                         'MULTILINESTRING' | 'MULTIPOINT' | 'MULTIPOLYGON' | 'MULTISURFACE' |
                                                                                         'POINT' | 'POLYGON' | 'POLYHEDRALSURFACE' | 'TIN' | 'TRIANGLE' -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-well_known_text_representation($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-geometrycollection_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse geometrycollection_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-geometrycollection_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(19, $input, $state)"/>    <!-- space | 'CIRCULARSTRING' | 'COMPOUNDCURVE' | 'CURVEPOLYGON' |
                                                                                         'GEOMETRYCOLLECTION' | 'LINESTRING' | 'MULTICURVE' |
                                                                                         'MULTILINESTRING' | 'MULTIPOINT' | 'MULTIPOLYGON' | 'MULTISURFACE' |
                                                                                         'POINT' | 'POLYGON' | 'POLYHEDRALSURFACE' | 'TIN' | 'TRIANGLE' -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-well_known_text_representation($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-geometrycollection_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'geometrycollection_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse geometrycollection_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-geometrycollection_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(12, $input, $state)"/>             <!-- 'GEOMETRYCOLLECTION' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(19, $input, $state)"/> <!-- space | 'CIRCULARSTRING' | 'COMPOUNDCURVE' | 'CURVEPOLYGON' |
                                                                                            'GEOMETRYCOLLECTION' | 'LINESTRING' | 'MULTICURVE' |
                                                                                            'MULTILINESTRING' | 'MULTIPOINT' | 'MULTIPOLYGON' | 'MULTISURFACE' |
                                                                                            'POINT' | 'POLYGON' | 'POLYHEDRALSURFACE' | 'TIN' | 'TRIANGLE' -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] != 3                                            (: empty_set :)
                    and $state[$p:lk] != 4                                            (: z_m :)
                    and $state[$p:lk] != 5                                            (: left_paren :)
                    and $state[$p:lk] != 66                                           (: space space :)
                    and $state[$p:lk] != 130">                                      <!-- space z_m -->
          <xsl:variable name="state" select="p:memoized($state, 14)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 14, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 14, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-geometrycollection_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'geometrycollection_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production tin_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-tin_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>   <!-- space | empty_set | left_paren -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-triangle_text_body($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-tin_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse tin_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-tin_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>     <!-- space | empty_set | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-triangle_text_body($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-tin_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'tin_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse tin_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-tin_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(22, $input, $state)"/>             <!-- 'TIN' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(7, $input, $state)"/> <!-- space | empty_set | left_paren -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] != 3                                            (: empty_set :)
                    and $state[$p:lk] != 4                                            (: z_m :)
                    and $state[$p:lk] != 5                                            (: left_paren :)
                    and $state[$p:lk] != 66                                           (: space space :)
                    and $state[$p:lk] != 130">                                      <!-- space z_m -->
          <xsl:variable name="state" select="p:memoized($state, 13)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 13, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 13, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-tin_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'tin_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production polyhedralsurface_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-polyhedralsurface_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>   <!-- space | empty_set | left_paren -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-polygon_text_body($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-polyhedralsurface_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse polyhedralsurface_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-polyhedralsurface_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>     <!-- space | empty_set | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-polygon_text_body($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-polyhedralsurface_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'polyhedralsurface_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse polyhedralsurface_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-polyhedralsurface_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(21, $input, $state)"/>             <!-- 'POLYHEDRALSURFACE' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(7, $input, $state)"/> <!-- space | empty_set | left_paren -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] != 3                                            (: empty_set :)
                    and $state[$p:lk] != 4                                            (: z_m :)
                    and $state[$p:lk] != 5                                            (: left_paren :)
                    and $state[$p:lk] != 66                                           (: space space :)
                    and $state[$p:lk] != 130">                                      <!-- space z_m -->
          <xsl:variable name="state" select="p:memoized($state, 12)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 12, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 12, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-polyhedralsurface_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'polyhedralsurface_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production multipolygon_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multipolygon_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>   <!-- space | empty_set | left_paren -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-polygon_text_body($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-multipolygon_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse multipolygon_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multipolygon_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>     <!-- space | empty_set | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-polygon_text_body($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-multipolygon_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'multipolygon_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse multipolygon_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multipolygon_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(17, $input, $state)"/>             <!-- 'MULTIPOLYGON' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(7, $input, $state)"/> <!-- space | empty_set | left_paren -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] != 3                                            (: empty_set :)
                    and $state[$p:lk] != 4                                            (: z_m :)
                    and $state[$p:lk] != 5                                            (: left_paren :)
                    and $state[$p:lk] != 66                                           (: space space :)
                    and $state[$p:lk] != 130">                                      <!-- space z_m -->
          <xsl:variable name="state" select="p:memoized($state, 11)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 11, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 11, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-multipolygon_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'multipolygon_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse surface_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-surface_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(10, $input, $state)"/>          <!-- empty_set | left_paren | 'CURVEPOLYGON' -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 11">                                        <!-- 'CURVEPOLYGON' -->
          <xsl:variable name="state" select="p:consume(11, $input, $state)"/>       <!-- 'CURVEPOLYGON' -->
          <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>     <!-- space | empty_set | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-curvepolygon_text_body($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-polygon_text_body($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'surface_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production multisurface_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multisurface_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(15, $input, $state)"/>  <!-- space | empty_set | left_paren | 'CURVEPOLYGON' -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-surface_text($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-multisurface_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse multisurface_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multisurface_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(15, $input, $state)"/>    <!-- space | empty_set | left_paren | 'CURVEPOLYGON' -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-surface_text($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-multisurface_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'multisurface_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse multisurface_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multisurface_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 18">                                        <!-- 'MULTISURFACE' -->
          <xsl:variable name="state" select="p:consume(18, $input, $state)"/>       <!-- 'MULTISURFACE' -->
          <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:l1] eq 2">                                  <!-- space -->
                <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/> <!-- space | empty_set | z_m | left_paren -->
                <xsl:variable name="state" as="item()+">
                  <xsl:choose>
                    <xsl:when test="$state[$p:lk] eq 98">                           <!-- space empty_set -->
                      <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                      <xsl:sequence select="$state"/>
                    </xsl:when>
                    <xsl:when test="$state[$p:lk] eq 162">                          <!-- space left_paren -->
                      <xsl:variable name="state" select="p:lookahead3(15, $input, $state)"/> <!-- space | empty_set | left_paren | 'CURVEPOLYGON' -->
                      <xsl:sequence select="$state"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:sequence select="$state"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] != 3                                      (: empty_set :)
                          and $state[$p:lk] != 4                                      (: z_m :)
                          and $state[$p:lk] != 5                                      (: left_paren :)
                          and $state[$p:lk] != 66                                     (: space space :)
                          and $state[$p:lk] != 130">                                <!-- space z_m -->
                <xsl:variable name="state" select="p:memoized($state, 10)"/>
                <xsl:choose>
                  <xsl:when test="$state[$p:lk] != 0">
                    <xsl:sequence select="$state"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:variable name="backtrack" select="$state"/>
                    <xsl:variable name="state" select="p:strip-result($state)"/>
                    <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/> <!-- space -->
                    <xsl:choose>
                      <xsl:when test="not($state[$p:error])">
                        <xsl:sequence select="p:memoize($backtrack, $state, 10, $backtrack[$p:e0], -1, -1)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:sequence select="p:memoize($backtrack, $state, 10, $backtrack[$p:e0], -2, -2)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] = -1
                           or $state[$p:lk] = 66                                      (: space space :)
                           or $state[$p:lk] = 130">                                 <!-- space z_m -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 4">                                   <!-- z_m -->
                <xsl:variable name="state" select="p:consume(4, $input, $state)"/>  <!-- z_m -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>     <!-- space | empty_set | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-multisurface_text($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 17">                                        <!-- 'MULTIPOLYGON' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-multipolygon_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 21">                                        <!-- 'POLYHEDRALSURFACE' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-polyhedralsurface_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-tin_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'multisurface_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production multilinestring_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multilinestring_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>   <!-- space | empty_set | left_paren -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-linestring_text_body($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-multilinestring_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse multilinestring_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multilinestring_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>     <!-- space | empty_set | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-linestring_text_body($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-multilinestring_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'multilinestring_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse multilinestring_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multilinestring_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(15, $input, $state)"/>             <!-- 'MULTILINESTRING' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(7, $input, $state)"/> <!-- space | empty_set | left_paren -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] != 3                                            (: empty_set :)
                    and $state[$p:lk] != 4                                            (: z_m :)
                    and $state[$p:lk] != 5                                            (: left_paren :)
                    and $state[$p:lk] != 66                                           (: space space :)
                    and $state[$p:lk] != 130">                                      <!-- space z_m -->
          <xsl:variable name="state" select="p:memoized($state, 9)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 9, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 9, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-multilinestring_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'multilinestring_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse curve_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-curve_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(16, $input, $state)"/>          <!-- empty_set | left_paren | 'CIRCULARSTRING' | 'COMPOUNDCURVE' -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 9">                                         <!-- 'CIRCULARSTRING' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-circularstring_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 10">                                        <!-- 'COMPOUNDCURVE' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-compoundcurve_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-linestring_text_body($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'curve_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production multicurve_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multicurve_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(17, $input, $state)"/>  <!-- space | empty_set | left_paren | 'CIRCULARSTRING' | 'COMPOUNDCURVE' -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-curve_text($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-multicurve_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse multicurve_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multicurve_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(17, $input, $state)"/>    <!-- space | empty_set | left_paren | 'CIRCULARSTRING' | 'COMPOUNDCURVE' -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-curve_text($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-multicurve_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'multicurve_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse multicurve_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multicurve_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 14">                                        <!-- 'MULTICURVE' -->
          <xsl:variable name="state" select="p:consume(14, $input, $state)"/>       <!-- 'MULTICURVE' -->
          <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:l1] eq 2">                                  <!-- space -->
                <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/> <!-- space | empty_set | z_m | left_paren -->
                <xsl:variable name="state" as="item()+">
                  <xsl:choose>
                    <xsl:when test="$state[$p:lk] eq 98">                           <!-- space empty_set -->
                      <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                      <xsl:sequence select="$state"/>
                    </xsl:when>
                    <xsl:when test="$state[$p:lk] eq 162">                          <!-- space left_paren -->
                      <xsl:variable name="state" select="p:lookahead3(17, $input, $state)"/> <!-- space | empty_set | left_paren | 'CIRCULARSTRING' |
                                                                                                  'COMPOUNDCURVE' -->
                      <xsl:sequence select="$state"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:sequence select="$state"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] != 3                                      (: empty_set :)
                          and $state[$p:lk] != 4                                      (: z_m :)
                          and $state[$p:lk] != 5                                      (: left_paren :)
                          and $state[$p:lk] != 66                                     (: space space :)
                          and $state[$p:lk] != 130">                                <!-- space z_m -->
                <xsl:variable name="state" select="p:memoized($state, 8)"/>
                <xsl:choose>
                  <xsl:when test="$state[$p:lk] != 0">
                    <xsl:sequence select="$state"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:variable name="backtrack" select="$state"/>
                    <xsl:variable name="state" select="p:strip-result($state)"/>
                    <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/> <!-- space -->
                    <xsl:choose>
                      <xsl:when test="not($state[$p:error])">
                        <xsl:sequence select="p:memoize($backtrack, $state, 8, $backtrack[$p:e0], -1, -1)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:sequence select="p:memoize($backtrack, $state, 8, $backtrack[$p:e0], -2, -2)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] = -1
                           or $state[$p:lk] = 66                                      (: space space :)
                           or $state[$p:lk] = 130">                                 <!-- space z_m -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 4">                                   <!-- z_m -->
                <xsl:variable name="state" select="p:consume(4, $input, $state)"/>  <!-- z_m -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>     <!-- space | empty_set | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-multicurve_text($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-multilinestring_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'multicurve_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production multipoint_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multipoint_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>   <!-- space | empty_set | left_paren -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-point_text($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-multipoint_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse multipoint_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multipoint_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>     <!-- space | empty_set | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-point_text($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-multipoint_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'multipoint_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse multipoint_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-multipoint_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(16, $input, $state)"/>             <!-- 'MULTIPOINT' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(7, $input, $state)"/> <!-- space | empty_set | left_paren -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] != 3                                            (: empty_set :)
                    and $state[$p:lk] != 4                                            (: z_m :)
                    and $state[$p:lk] != 5                                            (: left_paren :)
                    and $state[$p:lk] != 66                                           (: space space :)
                    and $state[$p:lk] != 130">                                      <!-- space z_m -->
          <xsl:variable name="state" select="p:memoized($state, 7)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 7, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 7, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-multipoint_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'multipoint_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse collection_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-collection_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 16">                                        <!-- 'MULTIPOINT' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-multipoint_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 14                                            (: 'MULTICURVE' :)
                     or $state[$p:l1] = 15">                                        <!-- 'MULTILINESTRING' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-multicurve_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 12">                                        <!-- 'GEOMETRYCOLLECTION' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-geometrycollection_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-multisurface_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'collection_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse triangle_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-triangle_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>     <!-- space | empty_set | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-linestring_text($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(3, $input, $state)"/>     <!-- space | right_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:lookahead1(1, $input, $state)"/>     <!-- right_paren -->
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'triangle_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse triangle_text_body.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-triangle_text_body" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-triangle_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'triangle_text_body', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse triangle_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-triangle_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(23, $input, $state)"/>             <!-- 'TRIANGLE' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(7, $input, $state)"/> <!-- space | empty_set | left_paren -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] != 3                                            (: empty_set :)
                    and $state[$p:lk] != 4                                            (: z_m :)
                    and $state[$p:lk] != 5                                            (: left_paren :)
                    and $state[$p:lk] != 66                                           (: space space :)
                    and $state[$p:lk] != 130">                                      <!-- space z_m -->
          <xsl:variable name="state" select="p:memoized($state, 6)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 6, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 6, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-triangle_text_body($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'triangle_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production polygon_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-polygon_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>   <!-- space | empty_set | left_paren -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-linestring_text($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-polygon_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse polygon_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-polygon_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>     <!-- space | empty_set | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-linestring_text($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-polygon_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'polygon_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse polygon_text_body.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-polygon_text_body" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-polygon_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'polygon_text_body', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse polygon_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-polygon_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(20, $input, $state)"/>             <!-- 'POLYGON' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(7, $input, $state)"/> <!-- space | empty_set | left_paren -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] != 3                                            (: empty_set :)
                    and $state[$p:lk] != 4                                            (: z_m :)
                    and $state[$p:lk] != 5                                            (: left_paren :)
                    and $state[$p:lk] != 66                                           (: space space :)
                    and $state[$p:lk] != 130">                                      <!-- space z_m -->
          <xsl:variable name="state" select="p:memoized($state, 5)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 5, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 5, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-polygon_text_body($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'polygon_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse ring_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-ring_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(16, $input, $state)"/>          <!-- empty_set | left_paren | 'CIRCULARSTRING' | 'COMPOUNDCURVE' -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 9">                                         <!-- 'CIRCULARSTRING' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-circularstring_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 10">                                        <!-- 'COMPOUNDCURVE' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-compoundcurve_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-linestring_text_body($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'ring_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production curvepolygon_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-curvepolygon_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(17, $input, $state)"/>  <!-- space | empty_set | left_paren | 'CIRCULARSTRING' | 'COMPOUNDCURVE' -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-ring_text($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-curvepolygon_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse curvepolygon_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-curvepolygon_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(17, $input, $state)"/>    <!-- space | empty_set | left_paren | 'CIRCULARSTRING' | 'COMPOUNDCURVE' -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-ring_text($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-curvepolygon_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'curvepolygon_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse curvepolygon_text_body.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-curvepolygon_text_body" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-curvepolygon_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'curvepolygon_text_body', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse curvepolygon_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-curvepolygon_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 11">                                        <!-- 'CURVEPOLYGON' -->
          <xsl:variable name="state" select="p:consume(11, $input, $state)"/>       <!-- 'CURVEPOLYGON' -->
          <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:l1] eq 2">                                  <!-- space -->
                <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/> <!-- space | empty_set | z_m | left_paren -->
                <xsl:variable name="state" as="item()+">
                  <xsl:choose>
                    <xsl:when test="$state[$p:lk] eq 98">                           <!-- space empty_set -->
                      <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                      <xsl:sequence select="$state"/>
                    </xsl:when>
                    <xsl:when test="$state[$p:lk] eq 162">                          <!-- space left_paren -->
                      <xsl:variable name="state" select="p:lookahead3(17, $input, $state)"/> <!-- space | empty_set | left_paren | 'CIRCULARSTRING' |
                                                                                                  'COMPOUNDCURVE' -->
                      <xsl:sequence select="$state"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:sequence select="$state"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] != 3                                      (: empty_set :)
                          and $state[$p:lk] != 4                                      (: z_m :)
                          and $state[$p:lk] != 5                                      (: left_paren :)
                          and $state[$p:lk] != 66                                     (: space space :)
                          and $state[$p:lk] != 130">                                <!-- space z_m -->
                <xsl:variable name="state" select="p:memoized($state, 4)"/>
                <xsl:choose>
                  <xsl:when test="$state[$p:lk] != 0">
                    <xsl:sequence select="$state"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:variable name="backtrack" select="$state"/>
                    <xsl:variable name="state" select="p:strip-result($state)"/>
                    <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/> <!-- space -->
                    <xsl:choose>
                      <xsl:when test="not($state[$p:error])">
                        <xsl:sequence select="p:memoize($backtrack, $state, 4, $backtrack[$p:e0], -1, -1)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:sequence select="p:memoize($backtrack, $state, 4, $backtrack[$p:e0], -2, -2)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] = -1
                           or $state[$p:lk] = 66                                      (: space space :)
                           or $state[$p:lk] = 130">                                 <!-- space z_m -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 4">                                   <!-- z_m -->
                <xsl:variable name="state" select="p:consume(4, $input, $state)"/>  <!-- z_m -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>     <!-- space | empty_set | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-curvepolygon_text_body($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 20">                                        <!-- 'POLYGON' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-polygon_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-triangle_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'curvepolygon_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse surface_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-surface_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-curvepolygon_text_representation($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'surface_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse single_curve_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-single_curve_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(9, $input, $state)"/>           <!-- empty_set | left_paren | 'CIRCULARSTRING' -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 9">                                         <!-- 'CIRCULARSTRING' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-circularstring_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-linestring_text_body($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'single_curve_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production compoundcurve_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-compoundcurve_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(14, $input, $state)"/>  <!-- space | empty_set | left_paren | 'CIRCULARSTRING' -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-single_curve_text($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-compoundcurve_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse compoundcurve_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-compoundcurve_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(14, $input, $state)"/>    <!-- space | empty_set | left_paren | 'CIRCULARSTRING' -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-single_curve_text($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-compoundcurve_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'compoundcurve_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse compoundcurve_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-compoundcurve_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(10, $input, $state)"/>             <!-- 'COMPOUNDCURVE' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(14, $input, $state)"/> <!-- space | empty_set | left_paren | 'CIRCULARSTRING' -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] != 3                                            (: empty_set :)
                    and $state[$p:lk] != 4                                            (: z_m :)
                    and $state[$p:lk] != 5                                            (: left_paren :)
                    and $state[$p:lk] != 66                                           (: space space :)
                    and $state[$p:lk] != 130">                                      <!-- space z_m -->
          <xsl:variable name="state" select="p:memoized($state, 3)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 3, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 3, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-compoundcurve_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'compoundcurve_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production circularstring_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-circularstring_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(4, $input, $state)"/>   <!-- space | number -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-point($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-circularstring_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse circularstring_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-circularstring_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(4, $input, $state)"/>     <!-- space | number -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-point($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-circularstring_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'circularstring_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse circularstring_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-circularstring_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(9, $input, $state)"/>              <!-- 'CIRCULARSTRING' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(4, $input, $state)"/> <!-- space | number -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] != 3                                            (: empty_set :)
                    and $state[$p:lk] != 4                                            (: z_m :)
                    and $state[$p:lk] != 5                                            (: left_paren :)
                    and $state[$p:lk] != 66                                           (: space space :)
                    and $state[$p:lk] != 130">                                      <!-- space z_m -->
          <xsl:variable name="state" select="p:memoized($state, 2)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 2, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 2, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-circularstring_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'circularstring_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse the 1st loop of production linestring_text (zero or more). Use
   ! tail recursion for iteratively updating the lexer state.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-linestring_text-1">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="state" select="p:lookahead1(6, $input, $state)"/>       <!-- right_paren | comma -->
        <xsl:choose>
          <xsl:when test="$state[$p:l1] != 8">                                      <!-- comma -->
            <xsl:sequence select="$state"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:variable name="state" select="p:consume(8, $input, $state)"/>      <!-- comma -->
            <xsl:variable name="state" select="p:lookahead1(4, $input, $state)"/>   <!-- space | number -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="state" select="
              if ($state[$p:error]) then
                $state
              else
                p:parse-point($input, $state)
            "/>
            <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>   <!-- space | right_paren | comma -->
            <xsl:variable name="state" as="item()+">
              <xsl:choose>
                <xsl:when test="$state[$p:error]">
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:when test="$state[$p:l1] = 2">                                 <!-- space -->
                  <xsl:variable name="state" select="p:consume(2, $input, $state)"/> <!-- space -->
                  <xsl:sequence select="$state"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$state"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:sequence select="p:parse-linestring_text-1($input, $state)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Parse linestring_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-linestring_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="p:lookahead1(4, $input, $state)"/>     <!-- space | number -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-point($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>     <!-- space | right_paren | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:error]">
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:l1] = 2">                                   <!-- space -->
                <xsl:variable name="state" select="p:consume(2, $input, $state)"/>  <!-- space -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state" select="p:parse-linestring_text-1($input, $state)"/>
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'linestring_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse linestring_text_body.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-linestring_text_body" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-linestring_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'linestring_text_body', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse linestring_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-linestring_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(13, $input, $state)"/>             <!-- 'LINESTRING' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(4, $input, $state)"/> <!-- space | number -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] != 3                                            (: empty_set :)
                    and $state[$p:lk] != 4                                            (: z_m :)
                    and $state[$p:lk] != 5                                            (: left_paren :)
                    and $state[$p:lk] != 66                                           (: space space :)
                    and $state[$p:lk] != 130">                                      <!-- space z_m -->
          <xsl:variable name="state" select="p:memoized($state, 1)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 1, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 1, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-linestring_text_body($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'linestring_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse curve_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-curve_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 13">                                        <!-- 'LINESTRING' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-linestring_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 9">                                         <!-- 'CIRCULARSTRING' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-circularstring_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-compoundcurve_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'curve_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse m.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-m" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(2, $input, $state)"/>           <!-- number -->
    <xsl:variable name="state" select="p:consume(7, $input, $state)"/>              <!-- number -->
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'm', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse z.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-z" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(2, $input, $state)"/>           <!-- number -->
    <xsl:variable name="state" select="p:consume(7, $input, $state)"/>              <!-- number -->
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'z', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Try parsing z.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:try-z" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="state" select="p:lookahead1(2, $input, $state)"/>           <!-- number -->
    <xsl:variable name="state" select="p:consumeT(7, $input, $state)"/>             <!-- number -->
    <xsl:sequence select="$state"/>
  </xsl:function>

  <!--~
   ! Parse y.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-y" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(2, $input, $state)"/>           <!-- number -->
    <xsl:variable name="state" select="p:consume(7, $input, $state)"/>              <!-- number -->
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'y', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse x.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-x" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(2, $input, $state)"/>           <!-- number -->
    <xsl:variable name="state" select="p:consume(7, $input, $state)"/>              <!-- number -->
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'x', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse point.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-point" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-x($input, $state)
    "/>
    <xsl:variable name="state" select="p:lookahead1(0, $input, $state)"/>           <!-- space -->
    <xsl:variable name="state" select="p:consume(2, $input, $state)"/>              <!-- space -->
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-y($input, $state)
    "/>
    <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>           <!-- space | right_paren | comma -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(11, $input, $state)"/>    <!-- right_paren | number | comma -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 226">                                <!-- space number -->
                <xsl:variable name="state" select="p:lookahead3(8, $input, $state)"/> <!-- space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = 2274                                          (: space number space :)
                     or $state[$p:lk] = 6370                                          (: space number right_paren :)
                     or $state[$p:lk] = 8418">                                      <!-- space number comma -->
          <xsl:variable name="state" select="p:memoized($state, 15)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:variable name="state" select="
                if ($state[$p:error]) then
                  $state
                else
                  p:try-z($input, $state)
              "/>
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 15, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 15, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1">
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-z($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(8, $input, $state)"/>           <!-- space | right_paren | comma -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(11, $input, $state)"/>    <!-- right_paren | number | comma -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = 226">                                       <!-- space number -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-m($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'point', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse point_text.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-point_text" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(5, $input, $state)"/>           <!-- empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 3">                                         <!-- empty_set -->
          <xsl:variable name="state" select="p:consume(3, $input, $state)"/>        <!-- empty_set -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="p:consume(5, $input, $state)"/>        <!-- left_paren -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-point($input, $state)
          "/>
          <xsl:variable name="state" select="p:lookahead1(1, $input, $state)"/>     <!-- right_paren -->
          <xsl:variable name="state" select="p:consume(6, $input, $state)"/>        <!-- right_paren -->
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'point_text', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse point_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-point_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:consume(19, $input, $state)"/>             <!-- 'POINT' -->
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:l1] eq 2">                                        <!-- space -->
          <xsl:variable name="state" select="p:lookahead2(13, $input, $state)"/>    <!-- space | empty_set | z_m | left_paren -->
          <xsl:variable name="state" as="item()+">
            <xsl:choose>
              <xsl:when test="$state[$p:lk] eq 98">                                 <!-- space empty_set -->
                <xsl:variable name="state" select="p:lookahead3(12, $input, $state)"/> <!-- END | space | right_paren | comma -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:when test="$state[$p:lk] eq 162">                                <!-- space left_paren -->
                <xsl:variable name="state" select="p:lookahead3(2, $input, $state)"/> <!-- number -->
                <xsl:sequence select="$state"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$state"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state[$p:l1], subsequence($state, $p:lk + 1)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = 1122                                          (: space empty_set END :)
                     or $state[$p:lk] = 2146                                          (: space empty_set space :)
                     or $state[$p:lk] = 6242                                          (: space empty_set right_paren :)
                     or $state[$p:lk] = 7330                                          (: space left_paren number :)
                     or $state[$p:lk] = 8290">                                      <!-- space empty_set comma -->
          <xsl:variable name="state" select="p:memoized($state, 0)"/>
          <xsl:choose>
            <xsl:when test="$state[$p:lk] != 0">
              <xsl:sequence select="$state"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="backtrack" select="$state"/>
              <xsl:variable name="state" select="p:strip-result($state)"/>
              <xsl:variable name="state" select="p:consumeT(2, $input, $state)"/>   <!-- space -->
              <xsl:choose>
                <xsl:when test="not($state[$p:error])">
                  <xsl:sequence select="p:memoize($backtrack, $state, 0, $backtrack[$p:e0], -1, -1)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="p:memoize($backtrack, $state, 0, $backtrack[$p:e0], -2, -2)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:lk] = -1
                     or $state[$p:lk] = 66                                            (: space space :)
                     or $state[$p:lk] = 130">                                       <!-- space z_m -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(13, $input, $state)"/>          <!-- space | empty_set | z_m | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 4">                                         <!-- z_m -->
          <xsl:variable name="state" select="p:consume(4, $input, $state)"/>        <!-- z_m -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="p:lookahead1(7, $input, $state)"/>           <!-- space | empty_set | left_paren -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 2">                                         <!-- space -->
          <xsl:variable name="state" select="p:consume(2, $input, $state)"/>        <!-- space -->
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="state" select="
      if ($state[$p:error]) then
        $state
      else
        p:parse-point_text($input, $state)
    "/>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'point_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Parse well_known_text_representation.
   !
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:parse-well_known_text_representation" as="item()+">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="count" select="count($state)"/>
    <xsl:variable name="begin" select="$state[$p:e0]"/>
    <xsl:variable name="state" select="p:lookahead1(18, $input, $state)"/>          <!-- 'CIRCULARSTRING' | 'COMPOUNDCURVE' | 'CURVEPOLYGON' |
                                                                                         'GEOMETRYCOLLECTION' | 'LINESTRING' | 'MULTICURVE' |
                                                                                         'MULTILINESTRING' | 'MULTIPOINT' | 'MULTIPOLYGON' | 'MULTISURFACE' |
                                                                                         'POINT' | 'POLYGON' | 'POLYHEDRALSURFACE' | 'TIN' | 'TRIANGLE' -->
    <xsl:variable name="state" as="item()+">
      <xsl:choose>
        <xsl:when test="$state[$p:error]">
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 19">                                        <!-- 'POINT' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-point_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 9                                             (: 'CIRCULARSTRING' :)
                     or $state[$p:l1] = 10                                            (: 'COMPOUNDCURVE' :)
                     or $state[$p:l1] = 13">                                        <!-- 'LINESTRING' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-curve_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:when test="$state[$p:l1] = 11                                            (: 'CURVEPOLYGON' :)
                     or $state[$p:l1] = 20                                            (: 'POLYGON' :)
                     or $state[$p:l1] = 23">                                        <!-- 'TRIANGLE' -->
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-surface_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="state" select="
            if ($state[$p:error]) then
              $state
            else
              p:parse-collection_text_representation($input, $state)
          "/>
          <xsl:sequence select="$state"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="end" select="$state[$p:e0]"/>
    <xsl:sequence select="p:reduce($state, 'well_known_text_representation', $count, $begin, $end)"/>
  </xsl:function>

  <!--~
   ! Create a textual error message from a parsing error.
   !
   ! @param $input the input string.
   ! @param $error the parsing error descriptor.
   ! @return the error message.
  -->
  <xsl:function name="p:error-message" as="xs:string">
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="error" as="element(error)"/>

    <xsl:variable name="begin" select="xs:integer($error/@b)"/>
    <xsl:variable name="context" select="string-to-codepoints(substring($input, 1, $begin - 1))"/>
    <xsl:variable name="linefeeds" select="index-of($context, 10)"/>
    <xsl:variable name="line" select="count($linefeeds) + 1"/>
    <xsl:variable name="column" select="($begin - $linefeeds[last()], $begin)[1]"/>
    <xsl:variable name="expected" select="if ($error/@x or $error/@ambiguous-input) then () else p:expected-token-set($error/@s)"/>
    <xsl:sequence select="
      string-join
      (
        (
          if ($error/@o) then
            ('syntax error, found ', $p:TOKEN[$error/@o + 1])
          else
            'lexical analysis failed',
          '&#10;',
          'while expecting ',
          if ($error/@x) then
            $p:TOKEN[$error/@x + 1]
          else
          (
            '['[exists($expected[2])],
            string-join($expected, ', '),
            ']'[exists($expected[2])]
          ),
          '&#10;',
          if ($error/@o or $error/@e = $begin) then
            ()
          else
            ('after successfully scanning ', string($error/@e - $begin), ' characters beginning '),
          'at line ', string($line), ', column ', string($column), ':&#10;',
          '...', substring($input, $begin, 64), '...'
        ),
        ''
      )
    "/>
  </xsl:function>

  <!--~
   ! Consume one token, i.e. compare lookahead token 1 with expected
   ! token and in case of a match, shift lookahead tokens down such that
   ! l1 becomes the current token, and higher lookahead tokens move down.
   ! When lookahead token 1 does not match the expected token, raise an
   ! error by saving the expected token code in the error field of the
   ! lexer state.
   !
   ! @param $code the expected token.
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:consume" as="item()+">
    <xsl:param name="code" as="xs:integer"/>
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:when test="$state[$p:l1] eq $code">
        <xsl:variable name="begin" select="$state[$p:e0]"/>
        <xsl:variable name="end" select="$state[$p:b1]"/>
        <xsl:variable name="whitespace">
          <xsl:if test="$begin ne $end">
            <xsl:value-of select="substring($input, $begin, $end - $begin)"/>
          </xsl:if>
        </xsl:variable>
        <xsl:variable name="token" select="$p:TOKEN[1 + $state[$p:l1]]"/>
        <xsl:variable name="name" select="if (starts-with($token, &quot;'&quot;)) then 'TOKEN' else $token"/>
        <xsl:variable name="begin" select="$state[$p:b1]"/>
        <xsl:variable name="end" select="$state[$p:e1]"/>
        <xsl:variable name="node">
          <xsl:element name="{$name}">
            <xsl:sequence select="substring($input, $begin, $end - $begin)"/>
          </xsl:element>
        </xsl:variable>
        <xsl:sequence select="
          subsequence($state, $p:l1, 9),
          0, 0, 0,
          subsequence($state, 13),
          $whitespace/node(),
          $node/node()
        "/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="error">
          <xsl:element name="error">
            <xsl:choose>
              <xsl:when test="$state[$p:e1] &lt; $state[$p:memo]/@e">
                <xsl:sequence select="$state[$p:memo]/@*"/>
              </xsl:when>
              <xsl:otherwise>
              <xsl:attribute name="b" select="$state[$p:b1]"/>
              <xsl:attribute name="e" select="$state[$p:e1]"/>
              <xsl:choose>
                <xsl:when test="$state[$p:l1] lt 0">
                  <xsl:attribute name="s" select="- $state[$p:l1]"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:attribute name="o" select="$state[$p:l1]"/>
                  <xsl:attribute name="x" select="$code"/>
                </xsl:otherwise>
              </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:element>
        </xsl:variable>
        <xsl:sequence select="
          subsequence($state, 1, $p:error - 1),
          $error/node(),
          subsequence($state, $p:error + 1)
        "/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Consume one token, i.e. compare lookahead token 1 with expected
   ! token and in case of a match, shift lookahead tokens down such that
   ! l1 becomes the current token, and higher lookahead tokens move down.
   ! When lookahead token 1 does not match the expected token, raise an
   ! error by saving the expected token code in the error field of the
   ! lexer state. In contrast to p:consume, do not create any output.
   !
   ! @param $code the expected token.
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result.
   ! @return the updated state.
  -->
  <xsl:function name="p:consumeT" as="item()+">
    <xsl:param name="code" as="xs:integer"/>
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:error]">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:when test="$state[$p:l1] eq $code">
        <xsl:sequence select="
          subsequence($state, $p:l1, 9),
          0, 0, 0,
          subsequence($state, 13)
        "/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="error">
          <xsl:element name="error">
            <xsl:choose>
              <xsl:when test="$state[$p:e1] &lt; $state[$p:memo]/@e">
                <xsl:sequence select="$state[$p:memo]/@*"/>
              </xsl:when>
              <xsl:otherwise>
              <xsl:attribute name="b" select="$state[$p:b1]"/>
              <xsl:attribute name="e" select="$state[$p:e1]"/>
              <xsl:choose>
                <xsl:when test="$state[$p:l1] lt 0">
                  <xsl:attribute name="s" select="- $state[$p:l1]"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:attribute name="o" select="$state[$p:l1]"/>
                  <xsl:attribute name="x" select="$code"/>
                </xsl:otherwise>
              </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:element>
        </xsl:variable>
        <xsl:sequence select="
          subsequence($state, 1, $p:error - 1),
          $error/node(),
          subsequence($state, $p:error + 1)
        "/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Lookahead one token on level 1.
   !
   ! @param $set the code of the DFA entry state for the set of valid tokens.
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result stack.
   ! @return the updated state.
  -->
  <xsl:function name="p:lookahead1" as="item()+">
    <xsl:param name="set" as="xs:integer"/>
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:choose>
      <xsl:when test="$state[$p:l1] ne 0">
        <xsl:sequence select="$state"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="match" select="
          p:match($input, $state[$p:e0], $set),
          0, 0, 0
        "/>
        <xsl:sequence select="
          $match[1],
          subsequence($state, $p:b0, 2),
          $match,
          subsequence($state, 10)
        "/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! Lookahead one token on level 2.
   !
   ! @param $set the code of the DFA entry state for the set of valid tokens.
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result stack.
   ! @return the updated state.
  -->
  <xsl:function name="p:lookahead2" as="item()+">
    <xsl:param name="set" as="xs:integer"/>
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="match" select="
      if ($state[$p:l2] ne 0) then
        subsequence($state, $p:l2, 6)
      else
      (
        p:match($input, $state[$p:e1], $set),
        0, 0, 0
      )
    "/>
    <xsl:sequence select="
      $match[1] * 32 + $state[$p:l1],
      subsequence($state, $p:b0, 5),
      $match,
      subsequence($state, 13)
    "/>
  </xsl:function>

  <!--~
   ! Lookahead one token on level 3.
   !
   ! @param $set the code of the DFA entry state for the set of valid tokens.
   ! @param $input the input string.
   ! @param $state lexer state, error indicator, and result stack.
   ! @return the updated state.
  -->
  <xsl:function name="p:lookahead3" as="item()+">
    <xsl:param name="set" as="xs:integer"/>
    <xsl:param name="input" as="xs:string"/>
    <xsl:param name="state" as="item()+"/>

    <xsl:variable name="match" select="
      if ($state[$p:l3] ne 0) then
        subsequence($state, $p:l3, 3)
      else
        p:match($input, $state[$p:e2], $set)
    "/>
    <xsl:sequence select="
      $match[1] * 1024 + $state[$p:lk],
      subsequence($state, $p:b0, 8),
      $match,
      subsequence($state, 13)
    "/>
  </xsl:function>

  <!--~
   ! Reduce the result stack, creating a nonterminal element. Pop
   ! $count elements off the stack, wrap them in a new element
   ! named $name, and push the new element.
   !
   ! @param $state lexer state, error indicator, and result.
   ! @param $name the name of the result node.
   ! @param $count the number of child nodes.
   ! @param $begin the input index where the nonterminal begins.
   ! @param $end the input index where the nonterminal ends.
   ! @return the updated state.
  -->
  <xsl:function name="p:reduce" as="item()+">
    <xsl:param name="state" as="item()+"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:param name="count" as="xs:integer"/>
    <xsl:param name="begin" as="xs:integer"/>
    <xsl:param name="end" as="xs:integer"/>

    <xsl:variable name="node">
      <xsl:element name="{$name}">
        <xsl:sequence select="subsequence($state, $count + 1)"/>
      </xsl:element>
    </xsl:variable>
    <xsl:sequence select="subsequence($state, 1, $count), $node/node()"/>
  </xsl:function>

  <!--~
   ! Strip result from lexer state, in order to avoid carrying it while
   ! backtracking.
   !
   ! @param $state the lexer state after an alternative failed.
   ! @return the updated state.
  -->
  <xsl:function name="p:strip-result" as="item()+">
    <xsl:param name="state" as="item()+"/>

    <xsl:sequence select="subsequence($state, 1, $p:memo)"/>
  </xsl:function>

  <!--~
   ! Memoize the backtracking result that was computed at decision point
   ! $dpi for input position $e0. Reconstruct state from the parameters.
   !
   ! @param $state the lexer state to be restored.
   ! @param $update the lexer state containing updates.
   ! @param $dpi the decision point id.
   ! @param $e0 the input position.
   ! @param $v the id of the successful alternative.
   ! @param $lk the new lookahead code.
   ! @return the reconstructed state.
  -->
  <xsl:function name="p:memoize" as="item()+">
    <xsl:param name="state" as="item()+"/>
    <xsl:param name="update" as="item()+"/>
    <xsl:param name="dpi" as="xs:integer"/>
    <xsl:param name="e0" as="xs:integer"/>
    <xsl:param name="v" as="xs:integer"/>
    <xsl:param name="lk" as="xs:integer"/>

    <xsl:variable name="memo" select="$update[$p:memo]"/>
    <xsl:variable name="errors" select="($memo, $update[$p:error])[.]"/>
    <xsl:variable name="memo">
      <xsl:element name="memo">
        <xsl:sequence select="$errors[@e = max($errors/xs:integer(@e))][last()]/@*, $memo/value"/>
        <xsl:element name="value">
          <xsl:attribute name="key" select="$e0 * 16 + $dpi"/>
          <xsl:sequence select="$v"/>
        </xsl:element>
      </xsl:element>
    </xsl:variable>
    <xsl:sequence select="
      $lk,
      subsequence($state, $p:b0, $p:memo - $p:b0),
      $memo/node(),
      subsequence($state, $p:memo + 1)
    "/>
  </xsl:function>

  <!--~
   ! Retrieve memoized backtracking result for decision point $dpi
   ! and input position $state[$p:e0] into $state[$p:lk].
   !
   ! @param $state lexer state, error indicator, and result.
   ! @param $dpi the decision point id.
   ! @return the updated state.
  -->
  <xsl:function name="p:memoized" as="item()+">
    <xsl:param name="state" as="item()+"/>
    <xsl:param name="dpi" as="xs:integer"/>

    <xsl:variable name="value" select="data($state[$p:memo]/value[@key = $state[$p:e0] * 16 + $dpi])"/>
    <xsl:sequence select="
      if ($value) then $value else 0,
      subsequence($state, $p:lk + 1)
    "/>
  </xsl:function>

  <!--~
   ! Parse start symbol well_known_text_representation from given string.
   !
   ! @param $s the string to be parsed.
   ! @return the result as generated by parser actions.
  -->
  <xsl:function name="p:parse-well_known_text_representation" as="item()*">
    <xsl:param name="s" as="xs:string"/>

    <xsl:variable name="memo">
      <xsl:element name="memo"/>
    </xsl:variable>
    <xsl:variable name="state" select="0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, false(), $memo/node()"/>
    <xsl:variable name="state" select="p:parse-well_known_text_representation($s, $state)"/>
    <xsl:variable name="error" select="$state[$p:error]"/>
    <xsl:choose>
      <xsl:when test="$error">
        <xsl:variable name="ERROR">
          <xsl:element name="ERROR">
            <xsl:sequence select="$error/@*, p:error-message($s, $error)"/>
          </xsl:element>
        </xsl:variable>
        <xsl:sequence select="$ERROR/node()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="subsequence($state, $p:result)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!--~
   ! The input filename, or string, if surrounded by curly braces.
  -->
  <xsl:param name="input" as="xs:string?" select="()"/>

  <!--~
   ! The (simple) main program.
  -->
  <xsl:template name="ldh:WKTParser">
    <xsl:param name="input" as="xs:string?" select="$input"/>

    <xsl:choose>
      <xsl:when test="empty($input)">
        <xsl:sequence select="error(xs:QName('main'), '&#xA;    Usage: java net.sf.saxon.Transform -xsl:wkt.xslt -it:main input=INPUT&#xA;&#xA;      parse INPUT, which is either a filename or literal text enclosed in curly braces')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="result" select="
          if (matches($input, '^\{.*\}$')) then
            p:parse-well_known_text_representation(substring($input, 2, string-length($input) - 2))
          else
            p:parse-well_known_text_representation(unparsed-text($input, 'utf-8'))
        "/>
        <xsl:choose>
          <xsl:when test="empty($result/self::ERROR)">
            <xsl:sequence select="$result"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="error(xs:QName('p:parse-well_known_text_representation'), concat('&#10;    ', replace($result, '&#10;', '&#10;    ')))"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>