const myName = "MyName";

document.addEventListener("click", function () {
    console.info("Click!");
});


function printMessage({date = Date.now(), name, text}) {
    let block = document.querySelector(".messages");
    block.innerHTML += `<div class="row">
        <div class="col-12 headline" >
                <span class="name">${ name }</span>
                (${ new Date(date).toLocaleString() })
        </div>
        <div class="col-12 alert text">${ text }</div>
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
            printMessage({
                name: myName,
                text: input.value
            });
            input.value = "";
        }
    });
});




