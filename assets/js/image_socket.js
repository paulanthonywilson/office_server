export class ImageSocket {
    constructor(img) {
        this.img = img;
        this.token = img.dataset.imageToken;
        this.wsUrl = img.dataset.wsUrl;
        this.scheduleHeartBeat();
    }

    connect() {
        console.log("connect");
        this.hasErrored = false;
        this.socket = new WebSocket(`${this.wsUrl}${this.token}/websocket`);
        let that = this;
        this.socket.onopen = () => { that.onOpen(); }
        this.socket.onclose = () => { that.onClose(); }
        this.socket.onerror = errorEvent => { that.onError(errorEvent); };
        this.socket.onmessage = messageEvent => { that.onMessage(messageEvent); };
        this.attemptReopen = true;
    }

    close() {
        this.attemptReopen = false;
        if (this.socket) this.socket.close();
        this.socket = null;
    }

    onOpen() {
        console.log("ws opened");
    }

    onClose() {
        this.maybeReopen();
        console.log("ws closed", this);
    }

    onError(errorEvent) {
        this.hasErrored = true;
        console.log("error", errorEvent);
    }

    onMessage(messageEvent) {
        if (typeof messageEvent.data == "string") {
            this.stringMessage(messageEvent.data);
        } else {
            this.binaryMessage(messageEvent.data);
        }
    }

    stringMessage(content) {
        if (content == "expired_token") {
            console.log("expired");
            window.location.reload()
        } else if (content.startsWith("token:")) {
            console.log("token refresh");
            this.token = content.slice(6);
        }
    }


    binaryMessage(content) {
        let oldImageUrl = this.img.src;
        let imageUrl = URL.createObjectURL(content);
        this.img.src = imageUrl;
        if (oldImageUrl.startsWith("blob:")) {
            URL.revokeObjectURL(oldImageUrl);
        }
    }

    isSocketClosed() {
        return this.socket == null || this.socket.readyState == 3;
    };

    maybeReopen() {
        let after = this.hasErrored ? 2000 : 0;
        setTimeout(() => {
            if (this.isSocketClosed() && this.attemptReopen) this.connect();
        }, after);
    };

    scheduleHeartBeat() {
        let that = this;
        this.heartBeatId = setTimeout(function () { that.sendHeartBeat(); }, 30000);
    }

    sendHeartBeat() {
        if (this.socket) {
            // Send a heartbeat message to the server to let it know
            // we're still alive, avoiding timeout.
            this.socket.send("💙");
        }
        this.scheduleHeartBeat();
    }
}