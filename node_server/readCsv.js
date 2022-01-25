const cp = require("child_process");

function parseLogLine(line) {
  const [time, co2, temp, humidity] = line.split(",");
  return {
    time,
    co2: Number(co2),
    temp: Number(temp),
    humidity: Number(humidity),
  };
}

async function getLastLines(pathToFile, numLines = 10) {
  const child = cp.exec(`tail ${pathToFile} -n ${numLines}`);

  let lines;
  for await (const data of child.stdout) {
    lines = data.split("\n");
  }

  // Get rid of the last element as it's an empty line
  lines.pop();

  return lines.map(parseLogLine);
}

async function main() {
  const csvData2 = await getLastLines("../sensing/air_quality.csv");
  console.log(csvData2);
}

main();
