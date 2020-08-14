#include "vec3.hpp"

ostream & operator<<(ostream & os, const vec3 & v)
{
    os << v[0] << " " << v[1] << " " << v[2];
    return os;
}
