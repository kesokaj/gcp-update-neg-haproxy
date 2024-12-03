from locust import HttpUser, task, between

class MyUser(HttpUser):
    wait_time = between(1, 3)  # Wait between 1 and 5 seconds between tasks

    @task
    def my_task(self):
        self.client.get("/")  # Replace with your desired endpoint