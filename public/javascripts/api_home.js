// api_home.js

$(function () {
  async function signIn () {
    let formData = new FormData();
    formData.set("username", "hamachi");
    formData.set("password", "brownies");

    let options = {
      method: "post",
      credentials: "include",
      body: formData,
    }

    try {
      return await fetch('/api/signin', options);
    } catch (err) {
      console.error(err);
    }
  }

  let topicTableTempl = Handlebars.compile($('#topicTableTempl').html());
  let topicTempl      = Handlebars.compile($('#topicTempl').html());
  let paginationLinksTempl = Handlebars.compile($('#paginationLinksTempl').html());
  Handlebars.registerPartial("topicTempl", $('#topicTempl').html());

  let topicsGen = generator('http://localhost:4567/api/topics');
  let data;

  async function getTopics (path="/api/topics") {
    try {
      let response = await fetch(path, {
        credentials: "include",
        contentType: "application/json",
      });
      data = await response.json();
      console.table(data);
      return data;
    } catch (error) {
      console.error(error);
      throw error;
    }
  }

  async function displayTopics(path="/api/topics") {
    await getTopics(path);
    console.log('data["topics"] =');
    console.table(data["topics"]);
    $('#topics-list').html(topicTableTempl({topics: data["topics"]}));
    $('#pagination-pages').html(paginationLinksTempl(data));
  }

  (async function () {
    await signIn();
    console.log("signed in");
    // await getTopics();
    await displayTopics();
  }());

  $('#pagination-pages').on("click", "a", function (e) {
    console.log(e.target);
    e.preventDefault();
    displayTopics($(e.target).attr("href"));
  });
});
