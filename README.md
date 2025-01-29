Given that the focus of this project is to handle a big volume of data sent from a front-end app as JSON and populate two databases with said data, I researched for gems
that would be able to allow the communication between my rails models and the databases, and the most used/up-to-date gems that I found were:

- mongoid for MongoDB
- activerecord-sqlserver-adapter for Microsoft SQL Server

To process big volumes of data, I used the sidekiq gem to create background jobs that process chunks of said data as per suggestion in the PDF and in the interview.

I also installed the pry gem to help stop execution at a given point in the code so I could debug as I coded.

Because the jobs run in the background, there was a need to know when all jobs ended so the frontend could be notified. At first I tried to use Server Sent Events (SSE) because it creates a unidirectional connection with the client and the client doesnt need to send any messages to the server, but rather the other way around. 

However, after implementing it I found out that it pinged the frontend too frequently when nothing was happening and decided to change to WebSockets and it was easier to implement without unrequested pinging. The websockets implemention was done using ActionCable.

Since I don't have the Pro version of Sidekiq in order to use batches and the callback function functionality that it provides, I needed to find a way to know when all jobs ended.

To do so, I used the redis gem to create a redis database and store a key-value pair of "jobs_count" with a value of the length of an array of arrays, where each subarray contained 1000 products. Whenever a job ends, the redis gem can then be used to decrement this value until it reaches 0. When it reaches 0, it sends a message through the web socket connection and the frontend can check the value of this message and know that it can then call an endpoint to obtain the products from the database.

To implement request pagination I used the kaminari gem, because that's what I use at work and I like its ease of use.

For testing I used RSpec as a suggestion from the interview/PDF. I only managed to to tests for the Product model (SQL Server database) due to lack of time given that my current didn't allow me the required time to develop tests. The tests for the ProductMdb model (MongoDB) are commented because they were giving me errors because it seems
that the objects that I create for testing persist between test runs and I didn't have more time to fix this issue. 

Before running the project, run the following command in the root of the project:

bundle install

To execute the tests for this project, run the following command in the root of the project:

bundle exec rspec

To run the backend, execute the following command:

rails s

And in a separate terminal, execute the following command to start Sidekiq:

bundle exec sidekiq