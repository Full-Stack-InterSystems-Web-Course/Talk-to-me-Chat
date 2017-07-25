var x = location.hostname; //Return the hostname of the current URL

const host = `ws://${ location.hostname }:57772`;
//const host = `ws://localhost:57772`;
//const host = "ws://"+x+":57772";


const myName = "MyName";
const myAvatar = `http://${ location.hostname }:57772/chattalktome/img/avatar.png`;

let URL = host + "/chattalktome/talk2me.web.websocketChat.cls",
ws = new WebSocket(URL);
console.log(URL)
document.addEventListener("click", function () {
    console.info("Click!");
});

function printMessage({date = Date.now(), name, text, avatar = ""}) {
    let block = document.querySelector(".messages");
    block.innerHTML += `
    <div class="row avatar">
        <div class="col-2 col-sm-2 col-md-1"><img src="${ avatar }" /></div> 
        <div class="col-10 col-sm-10 col-md-11">
        <div class="row">
            <div class="col-12 headline" >
                <span class="name">${ name }</span>
                (${ new Date(date).toLocaleString() })
            </div>
            <div class="col-12 alert text">${ text }</div>
        </div>
        </div>
    </div>`;
    document.body.scrollTop = 99999999;
}

document.addEventListener("DOMContentLoaded", () => {
    const input = document.querySelector("#msg-input");
    console.info("DOMContentLoaded");
    input.addEventListener("keydown", (event) => {
        console.info("keydown");
        if (input.value && event.keyCode === 13) {
            // printMessage({
            //     name: myName,
            //     text: input.value,
            //     avatar:myAvatar,
            // });
              ws.send(JSON.stringify({ "text": input.value }));
            input.value = "";
        }
    });
});

function initRoom (update = {}) {
	document.getElementById("header").textContent = update.roomName || "Chat is open";
	document.body.setAttribute("style", update.roomStyle || "");
	document.getElementById("msg-input").setAttribute("style", update.inputStyle || "");
}

ws.addEventListener("message", (m) => {
    console.log("Data received from the server:", JSON.stringify(m.data));
    let message = JSON.parse(m.data);
    if (message["error"])
        return console.error(`Server reporting an error: ${ message.error }`);
    if (message["updates"] instanceof Array) message["updates"].forEach(update => {
        if (update.type === "message")
            printMessage(update);
        else if (update.type === "notification")
            printMessage(update);
        else if (update.type === "init") 
			initRoom(update);
		else
            console.warn("Unhandled WebSocket message", message);
    });

});

// ws.addEventListener("message", ({ data }) => {
//     console.log("Data received from the server:", JSON.stringify(data));
// });


ws.addEventListener("open", () => {
    initRoom();
    printMessage({
        name: "System",
        text: "We're open!"
    });
    ws.send(JSON.stringify({
        name: myName,
        avatar: myAvatar
    }));
    console.log(myName + " is connected to the chat!");
});

ws.addEventListener("close", () => {
    printMessage({
        name: "System",
        text: "We're out!"
    });
    console.log("We are disconnected from the chat.");
});

ws.addEventListener("error", (err) => {
    printMessage({
       name: "System",
       text: "Connection error: " + err.toString()
    });
    console.error("Connection error:", err);

});

