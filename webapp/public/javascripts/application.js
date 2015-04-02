// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function initTopMenuToggle() {
  $('.topMenuToggle').click(function(event){
    $(this).nextAll('.subMenu').toggle();
  });
}

function reportExportCSV()
{
    var url = window.location.href;
    if (url.indexOf('?') > -1) {
       url += '&csv=true'
    } else {
       url += '?csv=true'
    }
    window.location = url;
    return false;
}


function deleteChannelMappingDialog(title, message, urlToGo){
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: {
            Delete: function () {
                if ($(this).find('#confirm_delete').is(":checked")) {
                  $(this).dialog("close");
                  window.location = urlToGo;
                }
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

function newPoolAvailabilityDialog(title, message) {
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: {
            Create: function () {
                if ($(this).find('#confirm_create').is(":checked")) {
                  $form = $('#new_pool');
                  $form.submit();
                  $(this).dialog("close");
                }
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

function disableRoomTypeChannelMappingDialog(title, message, confirm) {
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: [{
            text: confirm,
            click : function () {
              $form = $('.edit_room_type_channel_mapping');
              $form.submit();
              return true;
            }
        }],
        close: function (event, ui) {
            return false;
        }
    });
}

function disablePropertyChannelDialog(title, message, confirm) {
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: [{
            text: confirm,
            click : function () {
              $form = $('.edit_property_channel');
              $form.submit();
              return true;
            }
        }],
        close: function (event, ui) {
            return false;
        }
    });
}

function editPoolAvailabilityDialog(title, message) {
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: {
            Save: function () {
                if ($(this).find('#confirm_save').is(":checked")) {
                  $form = $('.edit_pool');
                  $form.submit();
                  $(this).dialog("close");
                }
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

function deleteRoomTypeDialog(title, message, urlToGo) {
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: {
            Delete: function () {
                if ($(this).find('#confirm_delete').is(":checked")) {
                  $(this).dialog("close");
                  window.location = urlToGo;
                }
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

function newMasterRateMappingsDialog(title, message, urlToGo) {
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: {
            Add: function () {
                if ($('.room_type_ids_check:checked').length > 0) {
                  $form = $('.new_master_rate_mappings');
                  $form.submit();
                  $(this).dialog("close");
                }
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

function deleteMasterRateMappingsDialog(title, message, urlToGo) {
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: {
            No: function () {
                $(this).dialog("close");
            },
            Yes: function () {
                window.location = urlToGo;
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

function deleteWarningMasterRateMappingsDialog(title, message, urlToGo) {
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: {
            Close: function () {
                $(this).dialog("close");
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

function deleteAccountDialog(title, message, urlToGo){
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: {
            No: function () {
                $(this).dialog("close");
            },
            Yes: function () {
                window.location = urlToGo;
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

function deletePropertyDialog(title, message, urlToGo){
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: {
            No: function () {
                $(this).dialog("close");
            },
            Yes: function () {
                window.location = urlToGo;
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

function newRoomTypeInventoryLinkDialog(title, message){
  $('<div></div>').appendTo('body')
    .html('<div>' + message + '</div>')
    .dialog({
        modal: true, title: title, zIndex: 10000, autoOpen: true,
        width: '550px', resizable: false,
        buttons: {
            Create: function () {
                dropdown = $(this).find($("#room_type_inventory_link_room_type_to_id"));
                if (dropdown.val() != '') {
                  $form = $('.new_room_type_inventory_links');
                  $form.submit();
                  $(this).dialog("close");
                }
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
};

jQuery(document).ready(function () {
  initTopMenuToggle();
});
