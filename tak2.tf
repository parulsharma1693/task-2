provider "aws" {
  region = "ap-south-1"
  profile = "parul123"
}


//Creating keypairs

resource "tls_private_key" "pkey" {
  algorithm   = "RSA"
                                  }

resource "aws_key_pair" "resource_key" {
  key_name   = "parul_1245678"
  public_key = tls_private_key.pkey.public_key_openssh 
				       }

resource "local_file" "key_file" {
  content = tls_private_key.pkey.private_key_pem
  filename = "parul123456789.pem"
   				 }


// Creating Security group

resource "aws_security_group" "securitygroup" {                      
  name        = "launch-wizard-1"
    vpc_id = "vpc-0ecfff09f9a49ad41"
  description = "this security group will allow traffic at port 80"
  
  ingress {
    description = "http is allowed"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
ingress {
    description = "ssh is allowed"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
	egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
  tags = {
    Name = "security_group"                   
  }
}

variable "enter_your_security_group" {
 type = string
  default = "launch-wizard-1"
				     }    


// Creating EFS Volume

resource "aws_efs_file_system" "efs_rn" {
  creation_token = "efs_rn"

  tags = {
    Name = "efs_file"
  }
}

// mounting efs

resource "aws_efs_mount_target" "mount_rn" {
  file_system_id = aws_efs_file_system.efs_rn.id
  subnet_id = "subnet-01f1af127cc80cf11"
  security_groups = [aws_security_group.securitygroup.id ] 
}                                           


// Launch instance

resource "aws_instance" "myinstance" {
  ami           = "ami-005956c5f0f757d37"
  instance_type = "t2.micro"
  key_name = aws_key_pair.resource_key.key_name
  subnet_id = "subnet-01f1af127cc80cf11"
   
  availability_zone = "ap-south-1b"
  
  vpc_security_group_ids = [ aws_security_group.securitygroup.id ]                
  
tags = {
   	  Name = "My_OS"
       	        }



// Creating remote connection

 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.pkey.private_key_pem
    host     = aws_instance.myinstance.public_ip
  		}

provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo service httpd start",
      "sudo systemctl enable httpd",
      "sudo yum install -y amazon-efs-utils",
      "sudo apt-get -y install amazon-efs-utils",
      "sudo yum install -y nfs-utils",
      "sudo apt-get -y install nfs-common", 
      "sudo file_system_id_1 = ${aws_efs_file_system.efs_rn.id}", 
      "sudo efs_mount_point_1 = /var/www/html",
      "sudo mkdir -p $efs_mount_point_1",
      "sudo test -f /sbin/mount.efs && echo $file_system_id_1:/$efs_mount_point_1 efs tls,_netdev >> /etc/fstab || echo $file_system_id_1.efs.ap-south-1.amazonaws.com:/$efs_mount_point_1 nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0 >> /etc/fstab ",
	"sudo test -f /sbin/mount.cfs && echo -e \n[client-info] \nsource=liw >> /etc/amazon/efs-utils.conf",
	"mount -a -t efs,nfs4, defaults",
	"sudo yum install git -y",
	"cd /var/www/html",
	"sudo yum install git -y",
	"mkfs.ext4 /dev/xvdf1",
	"mount /dev/xvdf1/ /var/www/html",
	"cd /var/www/html",
	"git clone https://github.com/pankajs3522/grapphy.git"

             ]
  			  

  	 
			  }
				     }

// Printing availability zone of OS  	

output "printaz" {
      value = aws_instance.myinstance.availability_zone
                 }






			  


// Printing IP address of OS

output "myos_ip" {
  value = aws_instance.myinstance.public_ip
      		 }


// Copying IP address of OS in a file

resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.myinstance.public_ip} > publicip.txt"
  				 }
				       }






// Creating S3 bucket

resource "aws_s3_bucket" "s3bucket" {
  bucket = "mybucket9858177812"
  acl    = "public-read"

  tags = {
    Name        = "Mybucket9858177812"
    Envirnoment = "Dev" 
  }
}



// Creating Cloudfront Distribution

locals {
s3_origin_id = "parul12345"
       }


resource "aws_cloudfront_distribution" "cloudfront_distribution" {
                  origin {
                      domain_name = aws_s3_bucket.s3bucket.bucket_regional_domain_name
                      origin_id   = local.s3_origin_id
                      
                         }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

                      forwarded_values {
                             query_string = false

                                     cookies {
                                         forward = "none"
                                             }
                                       }

                              viewer_protocol_policy = "allow-all"
                              min_ttl                = 0
 			      default_ttl            = 3600
    			      max_ttl                = 86400
  			 }

  # Cache behavior with precedence 0
 	 ordered_cache_behavior {
 		   path_pattern     = "/content/immutable/*"
      		   allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    		   cached_methods   = ["GET", "HEAD", "OPTIONS"]
    		   target_origin_id = local.s3_origin_id

    			forwarded_values {
      				query_string = false
      				headers      = ["Origin"]

      					cookies {
        					forward = "none"
      						}
    					 }

    				min_ttl                = 0
    				default_ttl            = 86400
   				max_ttl                = 31536000
    				compress               = true
    				viewer_protocol_policy = "redirect-to-https"
  				}
# Cache behavior with precedence 1
  		ordered_cache_behavior {
    			path_pattern     = "/content/*"
    			allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    			cached_methods   = ["GET", "HEAD"]
    			target_origin_id = local.s3_origin_id

    				forwarded_values {
      					query_string = false

      						cookies {
        						forward = "none"
      							}
   						 }

    					min_ttl                = 0
    					default_ttl            = 3600
    					max_ttl                = 86400
    					compress               = true
    					viewer_protocol_policy = "redirect-to-https"
  					}

  

  	restrictions {
   		 geo_restriction {
      			restriction_type = "whitelist"
      			locations        = ["US", "CA", "GB", "DE"]
    				 }
  		     }

  	     tags = {
    			Environment = "production"
  		    }

           viewer_certificate {
                cloudfront_default_certificate = true
  			      }
	}


resource "null_resource" "nulllocal1"  {


	provisioner "local-exec" {
	    command = "start chrome  ${aws_instance.myinstance.public_ip}"
  				 }
				       }


