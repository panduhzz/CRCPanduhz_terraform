document.addEventListener('DOMContentLoaded', function() {
    fetch('https://backend-function-app.azurewebsites.net/api/http_trigger?code=MfR4DU6mC9_zdj8BwQWffIOX0I__n6_u1-GtJYAyG5aMAzFulXsLZw==')
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
