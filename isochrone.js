let Queue = require('tinyqueue');

if (typeof Queue !== 'function' && Queue.default && typeof Queue.default === 'function') {
    Queue = Queue.default;
}

module.exports = function(graph, start, max_cost) {
    var costs = {};
    costs[start] = 0;
    var initialState = [0, [start], start];
    var queue = new Queue([initialState], function(a, b) { return a[0] - b[0]; });
    var explored = {};

    while (queue.length) {
        var state = queue.pop();
        var cost = state[0];
        var node = state[2];
        explored[node] = 1;

        var neighbours = graph[node];
        
        if (!neighbours) continue;

        Object.keys(neighbours).forEach(function(n) {
            var newCost = cost + neighbours[n];

            if (newCost < max_cost && (!(n in costs) || newCost < costs[n])) {
                costs[n] = newCost;
                if (!explored[n]) {
                    var newState = [newCost, state[1].concat([n]), n];
                    queue.push(newState);
                }
            }
        });
    }

    return costs;
};
