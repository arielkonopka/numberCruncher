# numberCruncher
This is a small pet project, kind of side project of a side project. I have two purposes: 
* learn Julia Lang
* find out, what can I do with the time series data

This is the first interation.


# Function
So far the program is not doing much, we do the reconstruction of the phase space of the preprocessed data.
We use  [PECUZAL algorithm, you can read about it here](https://iopscience.iop.org/article/10.1088/1367-2630/abe336), to reconstruct the pahse space and try to reconstruct the attractor. - If that is your starting point, I would suggest to [start here](https://ocw.mit.edu/courses/18-100a-real-analysis-fall-2020/pages/syllabus/) and [then perhaps here](https://books.google.pl/books?id=1daEDwAAQBAJ&hl=pl).
The data itself is preprocessed, before the reconstruction, we create two data frames with the deltas deltaC which is (close-close) and deltaO which for a change is (open-open).
Not sure if shouldn't apply log scale.
If the output is 3d, then we plot the result;
