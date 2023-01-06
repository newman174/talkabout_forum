// api_home.js

$(function () {
  async function signin () {
    let formData = new FormData();
    formData.set("username", "hamachi");
    formData.set("password", "brownies");

    let options = {
      method: "post",
      credentials: "include",
      body: formData,
    }

    try {
      return await fetch('/signin', options);
    } catch (err) {
      console.error(err);
    }
  }

  let topicTableTempl = Handlebars.compile($('#topicTableTempl').html());
  let topicTempl      = Handlebars.compile($('#topicTempl').html());
  Handlebars.registerPartial("topic", topicTempl);

  signin().then(console.log("signed in"));

  let topicsGen = generator('http://localhost:4567/api/topics');
  let topics;

  async function getTopics () {
    topicsGen.next()
    .then((response) => {
      console.log("response:")
      console.table(response);
      return response.value;
    })
    .then((returnedTopics) => {
      console.log("returnedTopics:")
      console.table(returnedTopics);
      topics = returnedTopics
      return topics;
    })
    .catch(console.error);
  }

  async function displayTopics() {
    await getTopics();
    const html = topicTableTempl({topics});
    $('#topics-list').html(html);
  }

  displayTopics();

  $('#get-topics').click(function (e) {
    e.preventDefault();
    displayTopics();
  });
});

// id
// body
// username
// user_id
// time_posted
// subject
// replies
// count_replies
// latest_reply
