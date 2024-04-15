document.addEventListener('DOMContentLoaded', function() {
    fetch('https://backend-function-app.azurewebsites.net/api/http_trigger?code=hTf1OaWWD9GD-QQTi8WJ-pQoVNTTswrVjZ9kA0_IKKDiAzFux1G9TA==')
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
