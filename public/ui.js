$(function() {
  return $("#menu").delegate("[id^=menu-]", "click", function(ev) {
    $("#menu").find(".pure-menu-selected").removeClass("pure-menu-selected").end();
    $(ev.target).parent("li").addClass("pure-menu-selected");
    return $("#main").find(".active").removeClass("active").end().find("#" + $(ev.target).attr("data-open")).addClass("active").end();
  });
});
