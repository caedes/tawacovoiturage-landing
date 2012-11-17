$(document).ready(function(){
  $("#sign_up").click(function(e){
    var that = $(this)
    e.preventDefault()

    if ( $('#subscribe').attr('submitted') ){
      return;
    }

    if ( $('.entry').val().length < 1 ){
      $('#form_div').effect('shake', { times: 4, distance: 3}, 40)
      return;
    }

    $.ajax({
      type: 'post',
      url: '/subscribe',
      data: $('#subscribe').serialize(),
      datatype: 'json',
      success: function(data){
        $("<div class='thanks'>Thanks! We'll update you through " +
          data.type + "!</div>")
            .hide()
            .appendTo('#container')
            .slideDown('fast')

        $('.sign_up').attr('disabled', true)
        $('#subscribe').attr('submitted', true)
      },
      error: function(data){
        $("<div class='yikes'>Yikes! Something messed up, try again.</div>")
            .hide()
            .appendTo('#container')
            .slideDown('fast')
      },
    })
  })
})
