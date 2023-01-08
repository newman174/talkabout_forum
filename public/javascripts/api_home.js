// api_home.js

$(function () {
  async function signIn() {
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
  let topicTempl = Handlebars.compile($('#topicTempl').html());
  let paginationLinksTempl = Handlebars.compile($('#paginationLinksTempl').html());
  Handlebars.registerPartial("topicTempl", $('#topicTempl').html());

  let topicsGen = generator('http://localhost:4567/api/topics');
  let data;

  async function getTopics(path = "/api/topics") {
    try {
      let response = await fetch(path, {
        credentials: "include",
        contentType: "application/json",
      });
      data = await response.json();
      return data;
    } catch (error) {
      console.error(error);
      throw error;
    }
  }

  async function displayTopicsList(path = "/api/topics") {
    await getTopics(path);
    // console.log('data["topics"] =');
    // console.table(data["topics"]);
    $('#topics-list').html(topicTableTempl({ topics: data["topics"] }));
    $('#pagination-pages').html(paginationLinksTempl(data));
  }

  // $('#topics-list').on("click", 'table, table :not(a)', async function (e) {
  $('#topics-list').on("click", 'table, table *', async function (e) {
    if (e.target.tagName === "A") return;

    e.stopPropagation();

    let $table = $(e.target).closest('table');
    let topicId = $table.attr("data-topic-id");
    if (!topicId) return;

    if ($table.is(':last-child') || $table.next()[0].tagName !== "DIV") {
      let bodyPath = `/api/displaytopic/${topicId}?topic_id=${topicId}`;
      let response = await fetch(bodyPath, {
        credentials: "include",
      });

      let responsebody = $.trim(await response.text());
      let $content = $($.trim(responsebody.match(/<main>((.|\n)*)<\/main>/i)[1]));
      $content.attr("data-topic-id", topicId);
      $content.hide();
      $table.after($content);
    }

    $table.next().slideToggle(300);
  });

  $('#topics-list').on("click", 'div.topic-body', async function (e) {
    if (e.target.tagName === "A") return;
    e.stopPropagation();
    $(e.target).closest('div.topic-body').slideToggle(200);
  });

  (async function () {
    await signIn();
    console.log("signed in");
    await displayTopicsList();
  }());

  $('#pagination-pages').on("click", "a", function (e) {
    e.preventDefault();
    displayTopicsList($(e.target).attr("href"));
  });
});
