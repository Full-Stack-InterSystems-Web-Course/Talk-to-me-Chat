/// WebSocket connections handler class
Class talk2me.web.websocketChat Extends %CSP.WebSocket
{

Parameter MaxLastMessages = 100;

Parameter DefaultAvatar = "https://localhost:57772/chattalktome/img/avatar.png";

Parameter SystemAvatar = "https://unpkg.com/svg-icon@0.8.1/dist/svg/material/person.svg";

/// Push updates interval in seconds
Parameter PushUpdatesInterval = 0.5;

/// Last message ID sent to the client
Property LastSentMessageId [ InitialExpression = 0 ];

Property MyName [ InitialExpression = {"AnonymousUser" _ $random(99999)} ];

Property MyAvatar [ InitialExpression = {..#DefaultAvatar} ];

/// Initialize the chat when someone connects
Method OnPreServer() As %Status
{
    if ($get(^ChatWebSocket("messages")) = "") {
    	set ^ChatWebSocket("messages") = 0
    }
    return $$$OK
}

/// Method that handles each new client in a new process.
Method Server() As %Status
{

    while (1) { // loop forever until client disconnects

    	set data = ..Read(, .status, ..#PushUpdatesInterval)
    	// if the status is not a read timeout error (for example, client disconnects)
    	if ($$$ISERR(status)) && ($$$GETERRORCODE(status) '= $$$CSPWebSocketTimeout) {
    		quit // break the while loop
    	}
    	if (data '= "") { // if any data came from the client
    		set err = ..ProcessClientData(data)
    		do:(err '= "") ..ReportError(err)
    	}

    	// check if no new messages appeared for the listening period (PushUpdatesInterval)
    	// and back to while loop beginning if not
    	continue:(^ChatWebSocket("messages") = ..LastSentMessageId)

    	// when new messages appeared, iterate over messages and send them to the client
    	// considering the MaxLastMessages limit
    	set lastId = $order(^ChatWebSocket("messages", ""), -1)
    	set limit = ..#MaxLastMessages
    	set messages = []
    	set id = lastId
    	while (id > ..LastSentMessageId) && (limit > 0) {
    		set message = ^ChatWebSocket("messages", id)
    		set avatar = $LISTGET(message, 4)
    		do messages.%Push({
    			"type": "message",
    			"date": ($LISTGET(message, 1)),
    			"name": ($LISTGET(message, 2)),
    			"text": ($LISTGET(message, 3)),
    			"avatar": ($case(avatar = "", 1: ..#DefaultAvatar, :avatar))
    		})
    		set limit = limit - 1
    		set id = $order(^ChatWebSocket("messages", id), -1)
    	}
    	set ..LastSentMessageId = lastId

    	// reverse an array to make messages aligned by date
    	set reversedMessages = []
    	for i=messages.%Size()-1:-1:0 {
    		do reversedMessages.%Push(messages.%Get(i))
    	}

    	// send updates to client
    	do ..Send({
			"updates": (reversedMessages)
		})

    } // end while loop

    return $$$OK
}

/// Process data received from client and return any error string
Method ProcessClientData(data) As %String
{

	set json = ""

	try { // try to decode client's message
		set json = ##class(%DynamicObject).%FromJSON(data)
	} catch (e) {
		set err = "Unable to parse incoming message: is it a valid JSON format?"
		set ^ChatWebSocket("errors", $I(^ChatWebSocket("errors"))) = $LB(err, e)
		return err
	}
	return:(json = "") "Unable to parse incoming message: is it in valid JSON format?"

	// update client's object (this class instance) or even post a new message
	set nameIsSet = (json.name '= "") && ('$IsObject(json.name))
	set avatarIsSet = (json.avatar '= "") && ('$IsObject(json.avatar))
	set textIsSet = (json.text '= "") && ('$IsObject(json.text))
	set:nameIsSet ..MyName = $EXTRACT(json.name, 1, 30)
	set:avatarIsSet ..MyAvatar = json.avatar
	if ((avatarIsSet || nameIsSet) && ('textIsSet)) {
		do ..Send({
			"updates": [{
				"type": "notification",
				"name": "System",
				"avatar": (..#SystemAvatar),
				"text": ("Your " _ $case(nameIsSet,
					1: "name",
					0: "avatar"
				) _ " was updated" _ $case(avatarIsSet && nameIsSet,
					1: " as well as your " _ $case(nameIsSet,
						1: "avatar",
						0: "name") _ ".",
					0: "."))
			}]
		})
		return ""
	}

	return:('textIsSet) "Unable to post your message:"
		_ " please, specify non-empty ""text"" property."
	set ^ChatWebSocket("messages", $I(^ChatWebSocket("messages"))) = $LB(
		$ZDATETIME($ZTIMESTAMP, 3, 7), // ISO
		..MyName,
		json.text,
		$case(..MyAvatar = ..#DefaultAvatar, 1: "", :..MyAvatar)
	)

	return ""
}

/// Report an error for the client
Method ReportError(err = "")
{
	return:(err = "")
	do ..Send({
		"error": (err),
		"updates": []
	})
}

/// Sends JSON object to the client. This method created for convenience.
Method Send(jsonObj)
{
	return ..Write((jsonObj).%ToJSON())
}

}
