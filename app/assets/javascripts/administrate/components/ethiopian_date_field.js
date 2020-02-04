$(function () {
  // Set the current calendar to the ethiopian calendar.
  const calendar = $.calendars.instance('ethiopian');

  // Whenever the user changes the visible value (ethiopian date format), 
  // this code updates the hidden value (gregorian date) so the server will
  // get the gregorian date in the POST / PATCH request.
  $('.display_value').change(function(event) {
    const date = $(this).val().split('-'); 
    const day = parseInt(date[0], 10); 
    const month = parseInt(date[1], 10);
    const year = parseInt(date[2], 10);
    const hiddenValue = $(this).next(); // This is the hidden value that stores the value that we actually send to the server.
    
    // Some really lazy validations for now. (MVP)
    let invalidDate = false;
    if (year === null || month === null || day === null || year < 1900) {
      invalidDate = true
    }

    if (invalidDate || !calendar.isValid(year, month, day)) {
      // Set hidden field to `null` so backend will complain that hidden value is invalid.
      // Scoped out validating using jquery for now because we would need to figure out how to connect
      // this logic to when a user clicks submit (i.e. the submit button is a separate component)
      $(hiddenValue).val(null);
    } else {
      const gregorianDate = calendar.toJSDate(year, month, day);
      $(hiddenValue).val(gregorianDate);
    }
  });
});

