; -----------------------------------------------------------------------------
; Copyright (c) Sean Stasiak. All rights reserved.
; Developed by: Sean Stasiak <sstasiak@protonmail.com>
; Refer to license terms in LICENSE; In the absence of such a file, contact
; me at the above email address and I can provide you with one.
; -----------------------------------------------------------------------------

EnableExplicit

#BUFFSIZE = 1024*1
#OK       = ~"  ok.\n"

#PORT     = "COM4"        ; hacks to get started with
#FILE     = "C:\prj\forth\mecrisp-stellaris-2.1.6\common\disassembler-m3.txt"

Global.i linenum = 0
Global.s line
Global   *buff   = 0

Procedure err( *b ) ; *b expected to contain an ASCII string
  PrintN( "ERR [line "+linenum+"]: "+PeekS(*b, -1, #PB_Ascii) )
  End -1
EndProcedure

Procedure mdl( file.s = #FILE, port.s = #PORT )

  If OpenSerialPort( 0, #PORT, 115200, #PB_SerialPort_NoParity, 8, 1, #PB_SerialPort_NoHandshake, 1024, 1024 ) = 0
    PokeS( *buff, "unable to open serial port.", -1, #PB_Ascii ) : err( *buff )
  EndIf

  ; send cr
  ; got "ok." ?
  ;    then continue
  WriteSerialPortString( 0, ~"\n", #PB_Ascii ) : Delay( 100 )
  ReadSerialPortData( 0, *buff, AvailableSerialPortInput(0) ) ; quasi 'flush'

  WriteSerialPortString( 0, ~"\n", #PB_Ascii )
  ReadSerialPortData( 0, *buff, Len(#OK) )
  If PeekS(*buff, Len(#OK), #PB_Ascii) <> #OK : err( *buff ) : EndIf

  Delay( 500 )
  If AvailableSerialPortInput(0) <> 0
    FillMemory( *buff, #BUFFSIZE )
    ReadSerialPortData( 0, *buff, AvailableSerialPortInput(0) )
    ShowMemoryViewer( *buff, 16 )
    PokeS( *buff, "line is not idle.", -1, #PB_Ascii ) : err( *buff )
  EndIf

  ; push lines, wait of #OK between them
  If ReadFile( 1, #FILE ) = 0
    PokeS( *buff, "unable to open input file: "+#FILE, -1, #PB_Ascii ) : err( *buff )
  EndIf

  Repeat
    line = ReadString( 1 )
    linenum + 1
    WriteSerialPortString( 0, line,  #PB_Ascii )
    WriteSerialPortString( 0, ~"\n", #PB_Ascii )
    Print("_")
    FillMemory( *buff, #BUFFSIZE ) ; wipe buff
    ReadSerialPortData( 0, *buff, Len(line+#OK) )
    Print("-")
;   ShowMemoryViewer( *buff, 256 ) : CallDebugger

    If Right(PeekS(*buff, Len(line+#OK), #PB_Ascii), Len(#OK)) <> #OK
      ShowMemoryViewer( *buff, 256 )
      err( *buff )
    EndIf
    Print(",")
  Until Eof( 1 )

  PrintN( #CRLF$+"done." );
  CloseFile( 1 )
  CloseSerialPort( 0 )
EndProcedure

If OpenConsole( "Mecrisp Downloader" )
  *buff = AllocateMemory( #BUFFSIZE )
  mdl( )
  FreeMemory( *buff ) : CloseConsole( )
EndIf