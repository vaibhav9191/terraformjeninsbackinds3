output "jenkins-url" {
    value = join("", ["http://", aws_instance.foo.public_dns, ":", "8080"])
  
}