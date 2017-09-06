import requests

print ("Hello Docker...")

requests.post("https://post.incomings.io/incomings/INCOMINGS_TOKEN", data={"title":"bar","message":"foo"})
