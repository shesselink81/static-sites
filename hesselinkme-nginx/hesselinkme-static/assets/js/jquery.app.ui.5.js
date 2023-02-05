var launchDateTime, txtMailTo;

$(document).ready(function () {

    $("a[href*='#']").click(function () {
        var hrefTarget = $(this).attr("href");
        var offsetTop = $(hrefTarget).offset().top;
        $("html, body").animate({ scrollTop: offsetTop }, 1000, 'swing')
        return false;
    });

    $.ajax({
        type: "GET",
        url: "webconfig.xml?" + Math.random(),
        dataType: "xml",
        success: loadConfig
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

    init_parallax();
    init_animate();
});

$(window).resize(function () {
    init_parallax();
    init_animate();
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

$('#nav').scrollspy();

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

function init_parallax() {
    $('#parallax-section-1 #bg1').parallax("50%", 0.6);
    $('#parallax-section-2 #bg2').parallax("50%", 0.6);
    $('#parallax-section-3 #bg3').parallax("50%", 0.6);
}

function init_animate() {

    $('.scrollblock .team-member, .scrollblock #contact_form, .scrollblock .contact-address').attr('style', '');

    var scrollorama = $.scrollorama({
        blocks: '.scrollblock', enablePin: false
    });

    scrollorama
        .animate('.team-member', { delay: -100, duration: 80, property: 'opacity', start: 0 })
        .animate('.team-member', { delay: -100, duration: 80, property: 'bottom', start: -80 })
        .animate('#contact_form', { delay: 400, duration: 100, property: 'opacity', start: 0 })
        .animate('#contact_form', { delay: 400, duration: 100, property: 'left', start: -80 })
        .animate('.contact-address', { delay: 400, duration: 100, property: 'opacity', start: 0 })
        .animate('.contact-address', { delay: 400, duration: 100, property: 'right', start: -80 });
}