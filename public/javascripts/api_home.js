// api_home.js

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



$(function () {
  signin().then(console.table);

  let topicTableTempl = Handlebars.compile($('#topicTableTempl').html());
  let topicTempl      = Handlebars.compile($('#topicTempl').html());
  Handlebars.registerPartial("topic", topicTempl);

  $('#get-topics').click(function (e) {
    e.preventDefault();
    fetch('/api/topics', {
      credentials: "include",
      contentType: "application/json",
    })
    .then((response) => response.json())
    .then((topics) => {
      console.table(topics);
      // console.log(Object.keys(topics[0]));
      $("body").append("hi world")
      $("body").append(topicTableTempl({topics}))
      return topics;
    });
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
