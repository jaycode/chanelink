$(function(){
    $(".pagination a").live("click",function(){
        $('#paginationData').html("<div class='paginationLoader'><img src='/images/ajax-loader.gif' /></div>");
        $.get(this.href, null, null, "script");
        return false;
    });
});