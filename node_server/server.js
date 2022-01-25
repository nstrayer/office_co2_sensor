// Require the framework and instantiate it
const fastify = require("fastify")({ logger: true });
const cp = require("child_process");

// Setup cross origin support
fastify.register(require("fastify-cors"), {
  origin: (origin, cb) => {
    console.log("received request from ", origin);
    if (/localhost/.test(origin)) {
      //  Request from localhost will pass
      cb(null, true);
      return;
    }
    // Generate an error on other origins, disabling access
    cb(new Error("Not allowed"));
  },
});

const port = 8888;

// Declare routes
fastify.get("/", async (request, reply) => {
  return { hello: "world" };
});

fastify.route({
  method: "GET",
  url: "/data",
  schema: {
    querystring: {
      nlines: { type: "integer" },
    },
  },
  handler: async function (request, reply) {
    const nlines = request.query.nlines || 10;
    const readings = await getLastLines("../sensing/air_quality.csv", nlines);
    console.log("Sent data to client");
    return { readings };
  },
});

// Run the server!
const start = async () => {
  console.log(`Spinning up server on port ${port}`);
  try {
    await fastify.listen(port, "0.0.0.0");
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};
start();

// Get the last lines from the logging csv
async function getLastLines(pathToFile, numLines = 10) {
  // Run tail bash command in separate process
  const child = cp.exec(`tail ${pathToFile} -n ${numLines}`);

  let lines;
  for await (const data of child.stdout) {
    lines = data.split("\n");
  }

  // Get rid of the last element as it's an empty line
  lines.pop();

  return lines.map(function parseLogLine(line) {
    const [time, co2, temp, humidity] = line.split(",");
    return {
      time,
      co2: Number(co2),
      temp: Number(temp),
      humidity: Number(humidity),
    };
  });
}
