// posts_generator.js

// create an async generator function
async function* generator(page) {
  // create an infinite loop
  // console.log(`page = ${page}`);
  do {
    // fetch the repo
    const response = await fetch(page, {
      credentials: "include",
      contentType: "application/json",
    });

    // parse the body text as JSON
    const data = await response.json();

    // // yield the info of each commit
    // for (let topic of data["topics"]) {
    //   yield topic;
    // }
    console.table(data);
    // yield(data["topics"]);
    yield(data);

    // extract the URL of the next page from the headers
    page = data["next"];

    // // if there's no "next page", break the loop.
    // if (page === undefined) {
    //   break;
    // }
  } while (page)
}

async function getTopics(page) {

  // set a counter
  let i = 0;

  for await (const topic of generator(page)) {

    // process the topic
    console.log(topic);

    // break at 5 topics
    if (++i === 5) {
      break;
    }
  }
}

// getTopics('http://localhost:4567/api/topics');
