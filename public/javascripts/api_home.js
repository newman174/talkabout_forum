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
  let paginationLinksTempl = Handlebars.compile($('#paginationLinksTempl').html());
  Handlebars.registerPartial("topicTempl", $('#topicTempl').html());

  signin().then(console.log("signed in"));

  let topicsGen = generator('http://localhost:4567/api/topics');
  let data;

  async function getTopics () {
    try {
      let response = await topicsGen.next();
      data = response.value;
      return data;
    } catch (error) {
      console.error(error);
      throw error;
    }
  }

  async function displayTopics() {
    await getTopics();
    $('#topics-list').html(topicTableTempl({topics: data["topics"]}));
    $('#pagination-pages').html(paginationLinksTempl(data));
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
