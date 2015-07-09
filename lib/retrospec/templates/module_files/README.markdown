# profiles 

## Module development setup

Install all the require gems to run test code
```shell
bundle install  (only need to do once)

```
## Running Tests

### Unit tests
This type of testing is fast and should be the first thing you do before comming your code.  Mistakes can be found
in a matter of seconds vs minutes/hours.  You can test your logic in a unit test.  The downside is you need to learn
how to write unit tests which can take some initial time getting used to.

```shell
bundle exec rake spec

```

### Integration Testing
This type of testing is somewhat manual and requires the use of vagrant and a test vm that is controlled by vagrant.
You can find the list of available test vms by running `vagrant status` in the root of the module directory.  There is 
at lot of magic happening in the vagrantfile that makes this easy.  Windows support with this module has not been added yet.

```shell

$ vagrant status
Current machine states:

win2012r2                 not created (vmware_fusion)
win2008r2                 not created (vmware_fusion)
centos6                   running (vmware_fusion)
```

To run a test first you need to define the test code located in module_root/tests directory.  This code is nothing more
than a bunch of puppet code that uses your manifest code.  You will be using puppet apply to run this code on the vm. 
Have a look inside the tests directory for examples.

Example test file
```
include profiles::default_linux
file{'/tmp/test.txt':
    ensure => file,
    content => 'Hello World'
}
```

There are a few ways to run the test code against a test vm, both of which have the same outcome.

```shell
bundle exec rake spec_prep
VAGRANT_MANIFEST=linux.pp vagrant provision centos6
```

or use the rake command which bundles the two commands together

```shell
bundle exec rake "vagrant_up[linux.pp,centos6]"
```

### Acceptance Tests 
Acceptance testing is sorta like combining unit testing and integration testing where it tests the code on real systems
automatically across a wide range of operating systems.  This is an advanced topic, so yu will want to master unit and
integration testing first before writing acceptance tests.

```shell
bundle exec rake beaker

```


## CI config doc
https://gitlab.com/gitlab-org/gitlab-ci-multi-runner/blob/master/docs/configuration/advanced-configuration.md