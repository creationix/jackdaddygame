Test long-poll with curl:

     while true; do curl -b cookies -c cookies http://localhost:8080/listen; done
