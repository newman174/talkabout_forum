$(function() {
  $("form.delete").submit(function (event) {
    event.preventDefault();

    var ok = confirm("Are you sure? this cannot be undone!");
    if (ok) {
      this.submit();
    }
  });

  $(".opacity-hover").hover(function () {
      // over
    $(this).css({opacity: 1});
    }, function () {
      // out
    $(this).css({opacity: 0.5});
    }
  );

  var pathname = window.location.pathname;
  if (pathname == "/signin" || pathname == "/register") {
    $("form.signin, form.register").submit(function(event) {
      if ($.trim($("input.username").val()) === "") {
        event.preventDefault();
        $("input.username").css({backgroundColor: '#feffa9', borderColor: 'red'});
        setTimeout(function() {
          $("input.username").css({backgroundColor: "", borderColor: ""});
        }, 1000);
      }

      if ($.trim($("input.password").val()) === "") {
        event.preventDefault();
        $("input.password").css({backgroundColor: '#feffa9', borderColor: 'red'});
        setTimeout(function() {
          $("input.password").css({backgroundColor: "", borderColor: ""});
        }, 1000);
      }
    });
  };

  $("form.search").submit(function(event) {
    if ($.trim($("input.search").val()) === "") {
      event.preventDefault();
      $("input.search").css({borderColor: "red"});
      setTimeout(function() {
        $("input.search").css({borderColor: ""});
      }, 1000);
    }
  });
});
