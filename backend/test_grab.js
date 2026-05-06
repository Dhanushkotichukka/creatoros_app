const axios = require('axios');

async function test() {
    try {
        const res = await axios.get('https://www.youtube.com/@FilmStackTelugu');
        const match = res.data.match(/"channelId":"([^"]+)"/);
        console.log("Channel ID:", match ? match[1] : "Not found");
    } catch (e) {
        console.error(e.message);
    }
}
test();
