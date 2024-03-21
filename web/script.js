document.addEventListener('DOMContentLoaded', function() {
    fetch('https://panduhzapi.azurewebsites.net/api/http_trigger?code=ZBPKszGpjyhaegsDyJA0E5uzUCmUxKoH5BgCboV5Sy7iAzFudwcxRw==')
  .then(response => {
    if (!response.ok) {
        throw new Error('Network response was not ok');
    }
    return response.json();
  })
  .then(data => {console.log(data);
    console.log("message" + data.message);
    console.log("counter" + data.count);
    document.querySelector('.visitor-counter').textContent = `Visitor Count: ${data.count}`;
})
  .catch(error => console.error('There has been a problem with your fetch operation:', error));

    console.log("The page has fully loaded");
});
