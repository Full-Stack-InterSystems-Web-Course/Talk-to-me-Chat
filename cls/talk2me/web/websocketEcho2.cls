/// http://localhost:57772/csp/docbook/DocBook.UI.Page.cls?KEY=GCGI_oper_config#GCGI_websockets
Class talk2me.web.websocketEcho2 Extends %CSP.WebSocket
{

Method OnPreServer() As %Status
{
   Quit $$$OK
}

Method Server() As %Status
{
   Set timeout=10
   For  {
      Set len=32656
      Set data=..Read(.len, .status, timeout)
      If $$$ISERR(status) {
         If $$$GETERRORCODE(status) = $$$CSPWebSocketClosed {
             Quit
         }
         If $$$GETERRORCODE(status) = $$$CSPWebSocketTimeout {
               Set status=..Write("Server timed-out at "_$Horolog)
         }
      }
      else {
         If data="exit" Quit
         Set status=..Write(data)
      }
   }
   Set status=..EndServer()
   Quit $$$OK
}

Method OnPostServer() As %Status
{
   Quit $$$OK
}

}
