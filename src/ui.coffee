$ ->
  $("#menu").delegate "[id^=menu-]", "click", (ev)->
    $("#menu")
      .find(".pure-menu-selected")
        .removeClass("pure-menu-selected")
    $(ev.target)
      .parent("li")
      .addClass("pure-menu-selected")
    $("#main")
      .find(".active")
        .removeClass("active")
    $("#main")
      .find("#"+$(ev.target).attr("data-open"))
        .addClass("active")
  $("#menuLink").click ->
    $("#layout").toggleClass("active")
    $("#menu").toggleClass("active")
    $("#menuLink").toggleClass("active")
