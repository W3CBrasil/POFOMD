package POFOMD::Controller::Root;
use utf8;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

POFOMD::Controller::Root - Root Controller for POFOMD

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut


sub base : Chained('/') PathPart('') CaptureArgs(0) { }
sub faq : Chained('base') Args(0) { }
sub sobre : Chained('base') Args(0) { } 
sub contato : Chained('base') Args(0) { }
sub todo : Chained('base') Args(0) { }

sub root : Chained('base') PathPart('') Args(0) { 
    my ($self, $c) = @_;
    $c->res->redirect('/dataset/estado-sao-paulo-2012');
}

=head2 default

Standard 404 error page

=cut

#sub default :Path {
#    my ( $self, $c ) = @_;
#    $c->response->body( 'Page not found' );
#    $c->response->status(404);
#}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Thiago Rondon

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
