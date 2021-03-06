#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_nolen_GLOBAL
#include "ppport.h"
#include "vutil.h"

/* --------------------------------------------------
 * $Revision: 2.5 $
 * --------------------------------------------------*/

typedef     SV *version_vxs;

MODULE = version::vxs PACKAGE = version::vxs

PROTOTYPES: DISABLE
VERSIONCHECK: DISABLE

BOOT:
        /* register the overloading (type 'A') magic */
        PL_amagic_generation++;
        newXS("version::vxs::()", XS_version__vxs_noop, file);
        newXS("version::vxs::(\"\"", XS_version__vxs_stringify, file);
        newXS("version::vxs::(0+", XS_version__vxs_numify, file);
        newXS("version::vxs::(cmp", XS_version__vxs_VCMP, file);
        newXS("version::vxs::(<=>", XS_version__vxs_VCMP, file);
        newXS("version::vxs::(bool", XS_version__vxs_boolean, file);
        newXS("version::vxs::(+", XS_version__vxs_noop, file);
        newXS("version::vxs::(-", XS_version__vxs_noop, file);
        newXS("version::vxs::(*", XS_version__vxs_noop, file);
        newXS("version::vxs::(/", XS_version__vxs_noop, file);
        newXS("version::vxs::(+=", XS_version__vxs_noop, file);
        newXS("version::vxs::(-=", XS_version__vxs_noop, file);
        newXS("version::vxs::(*=", XS_version__vxs_noop, file);
        newXS("version::vxs::(/=", XS_version__vxs_noop, file);
        newXS("version::vxs::(abs", XS_version__vxs_noop, file);
        newXS("version::vxs::nomethod", XS_version__vxs_noop, file);

void
new(...)
ALIAS:
    parse  =  1
PPCODE:
{
    SV *vs = ST(1);
    SV *rv;
    const char * classname = "";
    PERL_UNUSED_ARG(ix);

    if (items > 3 || items == 0)
        Perl_croak(aTHX_ "Usage: version::new(class, version)");

    if ( items == 1 || ! SvOK(vs) ) { /* no param or explicit undef */
        /* create empty object */
        vs = sv_newmortal();
        sv_setpvs(vs,"undef");
    }
    else if ( items == 2 && SvOK(ST(1)) ) {
        /* getting called as object or class method */
        vs = ST(1);
    }
    else if (items == 3 ) {
        vs = sv_newmortal();
        sv_setpvf(vs,"v%s",SvPV_nolen_const(ST(2)));
    }
    classname =
	sv_isobject(ST(0)) /* get the class if called as an object method */
	    ? HvNAME_get(SvSTASH(SvRV(ST(0))))
	    : (char *)SvPV_nolen(ST(0));

    rv = NEW_VERSION(vs);
    if ( strcmp(classname,"version::vxs") != 0 ) /* inherited new() */
#if PERL_VERSION == 5
        sv_bless(rv, gv_stashpv((char *)classname, GV_ADD));
#else
        sv_bless(rv, gv_stashpv(classname, GV_ADD));
#endif

    mPUSHs(rv);
}

void
stringify (lobj,...)
    version_vxs lobj
PPCODE:
{
    mPUSHs(VSTRINGIFY(lobj));
}

void
numify (lobj,...)
    version_vxs lobj
PPCODE:
{
    mPUSHs(VNUMIFY(lobj));
}

void
normal(ver)
    SV *ver
PPCODE:
{
    mPUSHs(VNORMAL(ver));
}

void
VCMP (lobj,...)
    version_vxs lobj
PPCODE:
{
    SV *rs;
    SV *rvs;
    SV *robj = ST(1);
    const IV  swap = (IV)SvIV(ST(2));

    if ( ! ISA_CLASS_OBJ(robj, "version::vxs") )
    {
        robj = NEW_VERSION(SvOK(robj) ? robj : newSVpvs_flags("undef", SVs_TEMP));
        sv_2mortal(robj);
    }
    rvs = SvRV(robj);

    if ( swap )
    {
        rs = newSViv(VCMP(rvs,lobj));
    }
    else
    {
        rs = newSViv(VCMP(lobj,rvs));
    }

    mPUSHs(rs);
}

void
boolean(lobj,...)
    version_vxs lobj
PPCODE:
{
    SV * const rs =
    	newSViv( VCMP(lobj,
		      sv_2mortal(NEW_VERSION(
		      		 sv_2mortal(newSVpvs("0"))
				))
		     )
	       );
    mPUSHs(rs);
}

void
noop(lobj,...)
    version_vxs lobj
CODE:
{
    Perl_croak(aTHX_ "operation not supported with version object");
}

void
is_alpha(lobj)
    version_vxs lobj
PPCODE:
{
    if ( hv_exists(MUTABLE_HV(lobj), "alpha", 5 ) )
        XSRETURN_YES;
    else
        XSRETURN_NO;
}

void
qv(...)
ALIAS:
    declare = 1
PPCODE:
{
    SV *ver = ST(0);
    SV * rv;
    const char * classname = "";
    PERL_UNUSED_ARG(ix);
    if ( items == 2 && SvOK(ST(1)) ) {
        /* getting called as object or class method */
        ver = ST(1);
    }
#ifdef SvVOK
    if ( !SvVOK(ver) ) { /* not already a v-string */
#endif
        rv = sv_newmortal();
        sv_setsv(rv,ver); /* make a duplicate */
        UPG_VERSION(rv, TRUE);
#ifdef SvVOK
    }
    else
    {
        rv = sv_2mortal(NEW_VERSION(ver));
    }
#endif
    classname =
	sv_isobject(ST(0)) /* get the class if called as an object method */
	    ? HvNAME_get(SvSTASH(SvRV(ST(0))))
	    : (char *)SvPV_nolen(ST(0));

    if ( items == 2 && strcmp(classname,"version") ) {
        /* inherited new() */
#if PERL_VERSION == 5
        sv_bless(rv, gv_stashpv((char *)classname, GV_ADD));
#else
        sv_bless(rv, gv_stashpv(classname, GV_ADD));
#endif
    }
    PUSHs(rv);
}

void
is_qv(lobj)
    version_vxs lobj
PPCODE:
{
    if ( hv_exists(MUTABLE_HV(lobj), "qv", 2 ) )
        XSRETURN_YES;
    else
        XSRETURN_NO;
}

void
_VERSION(sv,...)
    SV *sv
PPCODE:
{
    HV *pkg;
    GV **gvp;
    GV *gv;
    SV *ret;
    const char *undef;

    if (SvROK(sv)) {
        sv = (SV*)SvRV(sv);
        if (!SvOBJECT(sv))
            Perl_croak(aTHX_ "Cannot find version of an unblessed reference");
        pkg = SvSTASH(sv);
    }
    else {
        pkg = gv_stashsv(sv, FALSE);
    }

    gvp = pkg ? (GV**)hv_fetchs(pkg,"VERSION",FALSE) : Null(GV**);

    if (gvp && isGV(gv = *gvp) && (sv = GvSV(gv)) && SvOK(sv)) {
        sv = sv_mortalcopy(sv);
	if ( ! ISA_CLASS_OBJ(sv, "version::vxs"))
	    UPG_VERSION(sv, FALSE);
        undef = NULL;
    }
    else {
        sv = ret = &PL_sv_undef;
        undef = "(undef)";
    }

    if (items > 1) {
        SV *req = ST(1);

        if (undef) {
             if (pkg) {
                const char * const name = HvNAME_get(pkg);
#if PERL_VERSION == 5
                Perl_croak(aTHX_ "%s version %s required--this is only version ",
                            name, SvPVx_nolen_const(req));
#else
                Perl_croak(aTHX_ "%s does not define $%s::VERSION--version check failed",
                            name, name);
#endif
             }
             else {
#if PERL_VERSION >= 8
                 Perl_croak(aTHX_ "%s defines neither package nor VERSION--version check failed",
                            SvPVx_nolen_const(ST(0)) );
#else
                 Perl_croak(aTHX_ "%s does not define $%s::VERSION--version check failed",
                            SvPVx_nolen_const(ST(0)),
                            SvPVx_nolen_const(ST(0)) );
#endif
             }
        }

        if ( ! ISA_CLASS_OBJ(req, "version")) {
            /* req may very well be R/O, so create a new object */
            req = sv_2mortal( NEW_VERSION(req) );
        }

        if ( VCMP( req, sv ) > 0 ) {
            if ( hv_exists(MUTABLE_HV(SvRV(req)), "qv", 2 ) ) {
                req = VNORMAL(req);
                sv  = VNORMAL(sv);
            }
            else {
                req = VSTRINGIFY(req);
                sv  = VSTRINGIFY(sv);
            }
            Perl_croak(aTHX_ "%s version %"SVf" required--"
                "this is only version %"SVf"", HvNAME_get(pkg),
                SVfARG(sv_2mortal(req)),
                SVfARG(sv_2mortal(sv)));
        }
    }
    ST(0) = ret;

    /* if the package's $VERSION is not undef, it is upgraded to be a version object */
    if (ISA_CLASS_OBJ(sv, "version")) {
	ST(0) = sv_2mortal(VSTRINGIFY(sv));
    } else {
	ST(0) = sv;
    }

    XSRETURN(1);
}
