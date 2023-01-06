// posts_generator.js

// create an async generator function
async function* generator(repo) {

  // create an infinite loop
  for (;;) {

    // fetch the repo
    const response = await fetch(repo);

    // parse the body text as JSON
    const data = await response.json();

    // yield the info of each commit
    for (let commit of data) {
      yield commit;
    }

    // extract the URL of the next page from the headers
    const link = response.headers.get('Link');
    repo = /<(.*?)>; rel="next"/.exec(link)?. [1];

    // if there's no "next page", break the loop.
    if (repo === undefined) {
      break;
    }
  }
}

async function getCommits(repo) {

  // set a counter
  let i = 0;

  for await (const commit of generator(repo)) {

    // process the commit
    console.log(commit);

    // break at 90 commits
    if (++i === 90) {
      break;
    }
  }
}

getCommits('https://api.github.com/repos/tc39/proposal-temporal/commits');
