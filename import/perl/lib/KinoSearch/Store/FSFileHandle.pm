package KinoSearch::Store::FSFileHandle;
use KinoSearch;

1;

__END__

__BINDING__

Clownfish::Binding::Perl::Class->register(
    parcel            => "KinoSearch",
    class_name        => "KinoSearch::Store::FSFileHandle",
    bind_constructors => ['_open|do_open'],
);


