var launchDateTime, txtMailTo;

$(document).ready(function () {
    var $dataTarget;

    $(".col").click(function () {
        $dataTarget = $(this).data('target');

        $('.modal').css({ top: $(window).scrollTop() + (0.20 * $(window).innerHeight()), position: 'absolute' });

        if ($dataTarget != undefined) {
            $($dataTarget).modal('show');
            if ($(document).innerWidth() > 960) {
                var modal_height = $($dataTarget).height();
                var modal_width = $($dataTarget).width();
                var window_mid_y = $(document).innerHeight() / 2;
                var window_mid_x = ($(document).innerWidth() / 2) + 470;
                var modal_y = $($dataTarget).offset();
                var modal_x = $($dataTarget).offset();

                $($dataTarget).animate({ width: 0, height: 0, left: window_mid_x }, "fast").animate({ width: modal_width, height: modal_height, left: window_mid_x - 470 }, "fast");


                $($dataTarget).one("hide", { value: $dataTarget }, function () {
                    $('.modal').css({ top: '-35%', position: 'fixed' });
                    //$($dataTarget).animate({ width: 0, height: 0, left: window_mid_x });
                });

                $($dataTarget).one("hidden", { value: $dataTarget }, function () {
                    $($dataTarget).width(modal_width);
                    $($dataTarget).height(modal_height);
                });
            }
        }
        else {

        }
    });

    $.ajax({
        type: "GET",
        url: "webconfig.xml?" + Math.random(),
        dataType: "xml",
        success: loadConfig
    });

    var array_X = new Array();
    var array_Y = new Array();

    var index = 0;
    $(".col").each(function () {
        array_X.push($(this).position().left);
        array_Y.push($(this).position().top);
        index++;
    });

    index = 0;
    $(".col").each(function () {
        var _x = (Math.random() * 1000) + 1;
        var _y = (Math.random() * 1000) + 1;

        $(this).css({ top: _y, left: _x, 'position': 'absolute', 'opacity': 0 }).animate({ top: array_Y[index], left: array_X[index], opacity: 0.8 }, { duration: 1500, specialEasing: { width: 'linear', height: 'easeOutBounce' }, complete: function () { $(this).css({ 'position': 'static' }); } });
        index++;
    });

    init_FormValidator();
    CaptchaHandler();

    $("#btn_Send").click(function () {
        var txtName = $('#txtName');
        var txtEmail = $('#txtEmail');
        var txtMessage = $('#txtMessage');

        if ($('#form_contact_us').valid()) {
            $(document).ajaxStart(
                 function () {
                     $("#btn_Send").button('loading');
                 }
             );

            $(document).ajaxSuccess(
                function () {
                    $("#btn_Send").button('reset');
                    $("#form_contact_us")[0].reset();
                }
            );

            var ajaxRequest = $.ajax({
                url: "handlers/contact.php",
                type: "POST",
                data: { formType: 'contact', txtName: txtName.val(), txtEmail: txtEmail.val(), txtMessage: txtMessage.val(), txtMailTo: txtMailTo }
            });

            ajaxRequest.done(
            function (response) {
                var $message = '<i class="icon-ok"></i> ' + response;
                $("#contact_form_message").addClass("alert");
                $("#contact_form_message").html($message);
            });

            ajaxRequest.error(
            function (data) {
                var $message = '<i class="icon-remove"></i> ' + data.responseText;
                $("#contact_form_message").addClass("alert");
                $("#contact_form_message").html($message);
                $("#btn_Send").button('reset');
            });
        }
    });

    $('input, textarea').placeholder();

    if (!$.browser.mobile) {
        $("html").niceScroll({ scrollspeed: 200 });
        $(window).scroll(function () {
            $("html").getNiceScroll().resize();
        });
    }

});

function loadConfig(data) {
    $(data).find('launch-date-time').each(function () { launchDateTime = $(this).text(); });
    $(data).find('progress-status-percentage').each(function () {
        $('#progress-status').html($(this).text());
    });
    $(data).find('email-for-queries').each(function () { txtMailTo = $(this).text(); });
    $(data).find('facebook-page').each(function () {
        var link = $(this).text();
        $('#facebook-page').click(function () {
            location.href = link;
        });
    });
    $(data).find('twitter-page').each(function () {
        var link = $(this).text();
        $('#twitter-page').click(function () {
            location.href = link;
        });
    });
    $(data).find('googleplus-page').each(function () {
        var link = $(this).text();
        $('#googleplus-page').click(function () {
            location.href = link;
        });
    });
    $(data).find('pinterest-page').each(function () {
        var link = $(this).text();
        $('#pinterest-page').click(function () {
            location.href = link;
        });
    });
    $(data).find('youtube-page').each(function () {
        var link = $(this).text();
        $('#youtube-page').click(function () {
            location.href = link;
        });
    });
    $(data).find('vimeo-page').each(function () {
        var link = $(this).text();
        $('#vimeo-page').click(function () {
            location.href = link;
        });
    });

    $('#counter').countdown({
        finalDate: launchDateTime // DD MMMM YYYY, hh:mm:ss //'30 June 2013, 11:00:00'
    });
}

$('.carousel').carousel({
    interval: 2000
});

function CaptchaHandler() {
    var array_vals = new Array(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    var array_operators = new Array('+', '+');
    var index = parseInt(Math.random() * 10);
    index = (index == 0) ? index : (index - 1);
    var hidden_val_1 = array_vals[index];
    index = parseInt(Math.random() * 10);
    index = (index == 0) ? index : (index - 1);
    var hidden_val_2 = array_vals[index];
    index = parseInt(Math.random() * 10) % 2;
    var hidden_operator = array_operators[index];
    var result = 0;
    switch (hidden_operator) {
        case '*':
            result = hidden_val_1 * hidden_val_2;
            break;
        default:
            result = hidden_val_1 + hidden_val_2;
            break;
    }

    jQuery('label[for="txtCaptcha"]').html('<strong>What is ' + hidden_val_1 + ' ' + hidden_operator + ' ' + hidden_val_2 + ' = ?</strong>');

    var txtCaptchaResult = '<input type="hidden" id="txtCaptchaResult" />';
    jQuery("body").append(txtCaptchaResult);
    jQuery("#txtCaptchaResult").val(result);
}


function init_FormValidator() {
    $('#form_contact_us').validate({
        rules: {
            txtCaptcha: {
                equalTo: '#txtCaptchaResult'
            }
        },
        messages: {
            txtName: '<i class="icon-remove-sign"></i> required.',
            txtEmail: {
                required: '<i class="icon-remove-sign"></i> required.',
                email: '<i class="icon-info-sign"></i> invalid.</b>'
            },
            txtMessage: '<i class="icon-remove-sign"></i> required.',
            txtCaptcha: {
                required: '<i class="icon-remove-sign"></i> required.',
                equalTo: '<i class="icon-remove-sign"></i> wrong.'
            }
        },
        errorPlacement: function (error, element) {
            error.insertAfter(element);
            $('<div class="clearfix"></div>').insertBefore(error);
            $('<div class="clearfix"></div>').insertAfter(error);
            error.css({ left: element.position().left + (element.width() - error.width()), top: element.position().top + 3, position: 'absolute', 'z-index': 1100 });
            $(window).resize(function () {
                error.remove();
            });
        },
        invalidHandler: function (event, validator) {
            // 'this' refers to the form
            var errors = validator.numberOfInvalids();
            if (errors) {
            } else {
            }
        }
    });
}