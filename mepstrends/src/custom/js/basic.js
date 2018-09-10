// Basic javascript functionality needed for all pages (not just pages with tables)

$(document).ready(function() {

  var extlink_text = 'You are leaving a U.S. Department of Health and Human Services (HHS) Web site and entering a nongovernment Web site. \n\nHHS cannot attest to the accuracy of information provided by linked sites. \n\nLinking to an external Web site does not constitute an endorsement by HHS, or any of its employees, of the sponsors of the site or the products presented on the site. \n\nYou will be subject to the destination site\'s privacy policy when you leave the HHS site.\n\nPress \'OK\' to accept or \'Cancel\' to stay on this page.'

  $('.em-tooltip').tooltip({delay: {show: 500, hide: 10, trigger: "hover"}});

  $('.external-link').on('click',function(){
    return confirm(extlink_text);
  });

});
