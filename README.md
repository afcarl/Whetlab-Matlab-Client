Welcome to Whetlab!
===================

Whetlab automates the tuning of your favorite tool and optimizes its
performance.

What "tool" you ask? Well, it could be a lot of things.  It could be a
piece of software, whose performance is controlled by a few parameters
(such as a compression computer program or a machine learning
algorithm), or it could even be a complicated physical process (such
as the manufacture of a device or even a cooking recipe). As long as
your tool has a few knobs which you can crank up or down in order to
impact its performance, Whetlab can help you!

Whetlab works by suggesting tests you should run with your tool in
order to improve it. Once you have the result of these tests, you tell
Whetlab how they turned out and it will suggest new tests, and so on
until you're satisfied with the improved performance of your tool.

Installation Instructions
=========================

Installation is really simple.  Simply clone this repository and the path
to your local copy to MATLAB's search path. 

On UNIX or Mac platforms, this can be done by adding the following
line to the file ``$home/Documents/MATLAB/startup.m`` (if you don't already
have this file, simply create it): ::

    addpath(genpath('MY_LOCAL_COPY/Whetlab-Matlab-Client'))

where MY_LOCAL_COPY is the location of the cloned repository.

Getting Started
===============

We have written up a [tutorial](https://www.whetlab.com/docs/matlab-tutorial/) to get
you up and running quickly with whetlab.  If you're feeling really
impatient there are also a number of example scripts in this directory
to demonstrate the usage of the MATLAB client.  Just log in to
[Whetlab](https://www.whetlab.com), navigate to the Account page and
grab your api token to get started.
