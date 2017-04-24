
// Enter here the name of the node you want to listen to (eg dub, bcn0, bcn1, etc.)
node_name = "default"
time_interval = 1 * 5 * 1000; // interval in ms over which compute the throughput
var WebSocket = require('ws');
var ws = new WebSocket('ws://airscope.ie:8080/','ascope');
ws.on('open', function() {
  console.log("Connection successful");
  ws.send(node_name);
  console.log("Requesting node: " + node_name);
});
var is_first = true;
var tput_values = [];
setInterval(avgThroughput, time_interval);
ws.on('message', function(data, flags) {
  if (is_first) {
    // First message is list of available nodes
    is_first = false;
  } else {
    var parsed = JSON.parse(data);
    var throughput = parseFloat(parsed[1].values[0].value)  // * 1024 // Mbps to Kbps
    // console.log('Message from server: %s ', data)
    console.log('Parsed Downlink throughput: %d ', throughput);
    tput_values.push(throughput);
  }
});

function avgThroughput() {
  var avg_t = tput_values.reduce((x, y) => x + y) / tput_values.length;
  console.log('Avg throughput over %d seconds: %d', time_interval / 1000, avg_t)
  tput_values = [];
}
