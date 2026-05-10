import clips
env = clips.Environment()
class MyRouter:
    def __init__(self):
        self.output = ""
    def print(self, name, msg):
        self.output += msg

router = MyRouter()
env.add_router(router)
env.build('(defrule test-rule => (printout t "Hello from CLIPS!" crlf))')
env.reset()
env.run()
print("Captured output:", repr(router.output))
